// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20Capped is ERC20 {
    uint256 private _cap;

    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // When minting tokens
            require(
                totalSupply() + amount <= _cap,
                "ERC20Capped: cap exceeded"
            );
        }
    }
}

contract FourPool is ERC20Capped {
    ERC20 private _token;

    uint32 t_count;
    uint32 constant ref_fee_pct = 1;
    address payable _team;
    uint256 constant trade_fee_pct = 1;
    uint256 constant trade_fee_pct_divider = 2;
    uint256 constant base_price = 0.00001 ether;
    uint256 constant _factor = (10**12);

    event OnPool(
        uint32 t_count,
        uint32 a,
        uint32 b,
        uint32 c,
        uint32 d,
        uint32 reward,
        Pool pool
    );

    event OnUser(
        address indexed addr,
        uint32 staked,
        uint32 pool_amount,
        uint32 t_count,
        uint32 t_count_max,
        Pool join_pool,
        address referred_by
    );

    event OnReferral(address indexed addr, uint32 fee);

    event OnTrade(
        uint32 t_count,
        uint32 buy,
        uint32 sell,
        uint32 buy_liq,
        uint256 sell_liq
    );

    enum Pool {None, A, B, C, D}

    struct User {
        uint32 staked;
        uint32 pool_amount;
        uint32 t_count;
        uint32 t_count_max;
        Pool join_pool;
        address referred_by;
    }

    mapping(Pool => uint32) pool_amount;
    mapping(address => User) users;

    constructor(address payable team_)
        ERC20("4pool", "4PL")
        ERC20Capped(500 * (10**6))
    {
        _setupDecimals(0);
        _initialise_pools(1);
        _team = team_;
        _token = ERC20(address(this));

        emit OnTrade(
            0,
            0,
            0,
            uint32(cap() - totalSupply()),
            address(this).balance
        );
    }

    function _initialise_pools(uint32 _base) internal {
        pool_amount[Pool.A] = _base;
        pool_amount[Pool.B] = _base;
        pool_amount[Pool.C] = _base;
        pool_amount[Pool.D] = _base;
    }

    modifier handle_slippage(Pool _pool, uint32 _slippage_amount) {
        require(pool_amount[_pool] <= _slippage_amount, "low_slippage");
        _;
    }

    function trade_calc_fee(uint256 value) internal pure returns (uint256) {
        return ((value * trade_fee_pct) / 100) / trade_fee_pct_divider;
    }

    function reward_calc_fee(uint32 mint_amount)
        internal
        pure
        returns (uint32, uint32)
    {
        uint32 fee = ((mint_amount * ref_fee_pct) / 100);
        if (mint_amount <= 1 || fee < 1) {
            return (mint_amount, 0);
        } else {
            return (mint_amount - fee, fee);
        }
    }

    function buy() external payable {
        uint256 fee = trade_calc_fee(msg.value);
        _team.transfer(fee);
        _mint(msg.sender, msg.value / base_price);
        emit OnTrade(
            (t_count += 1),
            uint32(msg.value / base_price),
            0,
            uint32(cap() - totalSupply()),
            address(this).balance
        );
    }

    function sell(uint32 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "invalid_balance");
        uint256 value = _amount * base_price;
        uint256 fee = trade_calc_fee(value);

        _team.transfer(fee);

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(value - fee);

        emit OnTrade(
            (t_count += 1),
            0,
            _amount,
            uint32(cap() - totalSupply()),
            address(this).balance
        );
    }

    function reinvest(uint32 _slippage_amount)
        external
        handle_slippage(users[msg.sender].join_pool, _slippage_amount)
    {
        uint32 mint_amount = get_mint_amount();
        require(mint_amount > 0, "no_reward");

        (uint32 reward, uint32 fee) = reward_calc_fee(mint_amount);

        Pool pool = users[msg.sender].join_pool;
        // Adjust pool amounts
        pool_amount[pool] += reward;

        // Update user
        users[msg.sender].staked += reward;
        users[msg.sender].t_count = t_count + 1;
        users[msg.sender].t_count_max = r_t_max(users[msg.sender].staked);
        users[msg.sender].pool_amount += reward;

        if (fee > 0) {
            _mint(users[msg.sender].referred_by, fee);
            emit OnReferral(users[msg.sender].referred_by, fee);
        }

        emit_pool_events(pool, reward);
    }

    function add(uint32 _amount, uint32 _slippage_amount)
        external
        handle_slippage(users[msg.sender].join_pool, _slippage_amount)
    {
        require(_amount > 0, "sending_zero");
        require(balanceOf(msg.sender) >= _amount, "invalid_balance");
        Pool pool = users[msg.sender].join_pool;
        require(pool != Pool.None, "not_in_pool");

        uint32 mint_amount = get_mint_amount();
        (uint32 reward, uint32 fee) = reward_calc_fee(mint_amount);

        // Adjust pool amounts
        pool_amount[pool] += _amount + reward;

        // Update user
        users[msg.sender].staked += _amount + reward;
        users[msg.sender].t_count = t_count + 1;
        users[msg.sender].t_count_max = r_t_max(users[msg.sender].staked);
        users[msg.sender].pool_amount += _amount + reward;

        if (fee > 0) {
            _mint(users[msg.sender].referred_by, fee);
            emit OnReferral(users[msg.sender].referred_by, fee);
        }

        _burn(msg.sender, _amount);

        emit_pool_events(pool, reward);
    }

    function swap(Pool _pool, uint32 _slippage_amount)
        external
        handle_slippage(_pool, _slippage_amount)
    {
        require(users[msg.sender].join_pool != Pool.None, "not_in_pool");
        require(_pool != users[msg.sender].join_pool, "same_pool");

        uint32 amount = users[msg.sender].staked;
        uint32 mint_amount = get_mint_amount();
        (uint32 reward, uint32 fee) = reward_calc_fee(mint_amount);

        // Adjust pool amounts
        pool_amount[_pool] += amount;
        pool_amount[users[msg.sender].join_pool] -= amount;

        // Update user
        users[msg.sender].t_count = t_count + 1;
        users[msg.sender].t_count_max = r_t_max(users[msg.sender].staked);
        users[msg.sender].join_pool = _pool;
        users[msg.sender].pool_amount = pool_amount[_pool];

        if (reward > 0) {
            _mint(msg.sender, reward);
        }

        if (fee > 0) {
            _mint(users[msg.sender].referred_by, fee);
            emit OnReferral(users[msg.sender].referred_by, fee);
        }

        emit_pool_events(_pool, reward);
    }

    function join(
        uint32 _amount,
        Pool _pool,
        address _referredBy,
        uint32 _slippage_amount
    ) external handle_slippage(_pool, _slippage_amount) {
        require(_pool != Pool.None, "not_in_pool");
        require(users[msg.sender].join_pool == Pool.None, "already_in_pool");
        require(_amount > 0, "sending_zero");
        require(balanceOf(msg.sender) >= _amount, "invalid_balance");
        require(_referredBy != address(0), "invalid_ref");
        require(_referredBy != msg.sender, "self_ref");

        // Adjust _pool amounts
        pool_amount[_pool] += _amount;

        // Update user
        users[msg.sender].join_pool = _pool;
        users[msg.sender].staked = _amount;
        users[msg.sender].t_count = t_count + 1;
        users[msg.sender].t_count_max = r_t_max(_amount);
        users[msg.sender].pool_amount = pool_amount[_pool];
        users[msg.sender].referred_by = _referredBy;

        _burn(msg.sender, _amount);

        emit_pool_events(_pool, 0);
    }

    function leave(uint32 _slippage_amount)
        external
        handle_slippage(users[msg.sender].join_pool, _slippage_amount)
    {
        Pool pool = users[msg.sender].join_pool;
        require(pool != Pool.None, "not_in_pool");
        uint32 amount = users[msg.sender].staked;

        uint32 mint_amount = get_mint_amount();
        (uint32 reward, uint32 fee) = reward_calc_fee(mint_amount);

        // Adjust pool amounts
        pool_amount[pool] -= amount;

        // Update user
        delete users[msg.sender].join_pool;
        delete users[msg.sender].staked;
        delete users[msg.sender].t_count;
        delete users[msg.sender].t_count_max;
        delete users[msg.sender].pool_amount;

        _mint(msg.sender, amount + reward);

        if (fee > 0) {
            _mint(users[msg.sender].referred_by, fee);
            emit OnReferral(users[msg.sender].referred_by, fee);
        }

        emit_pool_events(pool, reward);
    }

    function emit_pool_events(Pool pool, uint32 reward) internal {
        emit OnPool(
            (t_count += 1),
            pool_amount[Pool.A],
            pool_amount[Pool.B],
            pool_amount[Pool.C],
            pool_amount[Pool.D],
            reward,
            pool
        );

        emit OnUser(
            msg.sender,
            users[msg.sender].staked,
            users[msg.sender].pool_amount,
            users[msg.sender].t_count,
            users[msg.sender].t_count_max,
            users[msg.sender].join_pool,
            users[msg.sender].referred_by
        );
    }

    function get_mint_amount() internal view returns (uint32 total) {
        if (users[msg.sender].join_pool == Pool.None) {
            return 0;
        }

        uint256 pool_total =
            pool_amount[Pool.A] +
                pool_amount[Pool.B] +
                pool_amount[Pool.C] +
                pool_amount[Pool.D];

        uint256 tcount =
            r_t_count(
                users[msg.sender].t_count_max,
                users[msg.sender].t_count,
                t_count
            );

        uint256 pool =
            r_pool(
                users[msg.sender].pool_amount,
                pool_amount[users[msg.sender].join_pool],
                pool_total
            );

        uint256 amount = r_amount(users[msg.sender].staked, cap());

        uint256 rate_total = r_total(pool, tcount, amount);

        total = r_mint(rate_total, cap() - totalSupply());
    }

    function r_mint(uint256 _total, uint256 _remaining)
        public
        pure
        returns (uint32 r)
    {
        r = uint32((_remaining * _total) / (_factor));
    }

    function r_amount(uint256 _amount, uint256 _max)
        public
        pure
        returns (uint256 r)
    {
        _amount *= _factor;
        r = _amount / _max;
    }

    function r_pool(
        uint256 _enter_amount,
        uint256 _exit_amount,
        uint256 _max
    ) public pure returns (uint256 r) {
        _exit_amount *= _factor;
        _enter_amount *= _factor;
        if (_exit_amount < _enter_amount) {
            return 0;
        }
        return (_exit_amount - _enter_amount) / (_max);
    }

    function r_total(
        uint256 _pool,
        uint256 _tcount,
        uint256 _amount
    ) public pure returns (uint256 r) {
        r = (_pool * _tcount * _amount) / (_factor * _factor);
    }

    function r_t_count(
        uint256 _max_tcount,
        uint256 _enter_count,
        uint256 _leave_count
    ) public pure returns (uint256) {
        _leave_count *= _factor;
        _enter_count *= _factor;
        uint256 _rate = (_leave_count - _enter_count) / (_max_tcount);
        if (_rate > _factor) {
            return _factor * 2;
        }
        return _rate * 2;
    }

    function r_t_max(uint256 _amount) public pure returns (uint32) {
        return uint32(sqrt(_amount));
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function ui() external view returns (uint256[12] memory acc) {
        acc[0] = t_count;
        acc[1] = pool_amount[Pool.A];
        acc[2] = pool_amount[Pool.B];
        acc[3] = pool_amount[Pool.C];
        acc[4] = pool_amount[Pool.D];
        acc[5] = cap() - totalSupply();
        acc[6] = address(this).balance;
        acc[7] = users[msg.sender].staked;
        acc[8] = users[msg.sender].pool_amount;
        acc[9] = users[msg.sender].t_count;
        acc[10] = users[msg.sender].t_count_max;
        acc[11] = uint256(users[msg.sender].join_pool);
    }
}
