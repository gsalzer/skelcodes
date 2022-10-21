// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.11;

import "./TeazersStorage.sol";
import "./TeazersEvents.sol";

contract TeazersBase is TeazersStorage, TeazersEvents {
    function registration(address _referrer) external payable blockReEntry() {
        preRegistration(msg.sender, _referrer);
    }

    function preRegistration(address _addr, address _referrer) internal {
        require((levelCost[1]) == msg.value, "Require .003 eth to register!");

        createAccount(_addr, _referrer, false);

        users[_referrer].directSales++;

        handlePositionX3(_addr, _referrer, _referrer, 1, false);
        handlePositionX4(_addr, _referrer, _referrer, 1, false);

        handlePayout(_addr, 0, 1);
        handlePayout(_addr, 1, 1);
    }

    function createAccount(
        address _addr,
        address _referrer,
        bool _initial
    ) internal {
        require(!users[_addr].exists, "Already a member!");

        if (!_initial) {
            require(users[_referrer].exists, "referrer dont exist!");
        }

        lastId++;

        users[_addr] = Account({
            id: lastId,
            referrer: _referrer,
            exists: true,
            directSales: 0,
            activeLevel: new uint8[](2)
        });
         
        idToAddress[lastId] = _addr;

        emit Registration(_addr, lastId, _referrer);
    }

    function purchaseLevel(uint8 _matrix, uint8 _level)
        external
        payable
        isMember(msg.sender)
        blockReEntry()
    {
        require((_matrix == 1 || _matrix == 2), "Invalid matrix identifier.");
        require((_level > 0 && _level <= TOP_LEVEL), "Invalid matrix level.");

        uint8 activeLevel = users[msg.sender].activeLevel[(_matrix - 1)];

        require((activeLevel < _level), "Already active at level!");
        require((activeLevel == (_level - 1)), "Level upgrade req. in order!");
        require((msg.value == levelCost[_level]), "Wrong amount transferred.");

        address referrer = users[msg.sender].referrer;

        emit Upgrade(msg.sender, referrer, _matrix, _level);

        if (_matrix == 1) {
            handlePositionX3(
                msg.sender,
                referrer,
                findActiveReferrer(msg.sender, referrer, 0, _level, true),
                _level,
                false
            );
        } else {
            handlePositionX4(
                msg.sender,
                referrer,
                findActiveReferrer(msg.sender, referrer, 1, _level, true),
                _level,
                false
            );
        }

        handlePayout(msg.sender, (_matrix - 1), _level);
    }

    function handlePositionX3(
        address _addr,
        address _mainReferrer,
        address _referrer,
        uint8 _level,
        bool _initial
    ) internal {
        Account storage member = users[_addr];

        member.activeLevel[0] = _level;
        member.x3Positions[_level] = X3({
            referrer: _referrer,
            placement: 0,
            directSales: 0,
            cycles: 0,
            passup: 0,
            reEntryCheck: 0
        });

        if (_initial) {
            return;
        } else if (_mainReferrer == _referrer) {
            users[_mainReferrer].x3Positions[_level].directSales++;
        } else {
            member.x3Positions[_level].reEntryCheck = 1;
        }

        referrerPlaceX3(_addr, _referrer, _level, false);
    }

    function referrerPlaceX3(
        address _addr,
        address _referrer,
        uint8 _level,
        bool passup
    ) internal {
        X3 storage position = users[_referrer].x3Positions[_level];

        emit PlacementX3(
            _addr,
            _referrer,
            _level,
            (position.placement + 1),
            passup
        );

        if (position.placement >= 2) {
            emit Cycle(_referrer, _addr, 1, _level);

            position.placement = 0;
            position.cycles++;

            if (_referrer != idToAddress[1]) {
                position.passup++;

                referrerPlaceX3(_referrer, position.referrer, _level, true);
            }
        } else {
            position.placement++;
        }
    }

    function handlePositionX4(
        address _addr,
        address _mainReferrer,
        address _referrer,
        uint8 _level,
        bool _initial
    ) internal {
        Account storage member = users[_addr];

        member.activeLevel[1] = _level;
        member.x4Positions[_level] = X4({
            referrer: _referrer,
            directSales: 0,
            cycles: 0,
            passup: 0,
            cycle: 0,
            reEntryCheck: 0,
            placementSide: 0,
            placedUnder: _referrer,
            placementFirstLevel: new address[](0),
            placementLastLevel: 0
        });

        if (_initial) {
            return;
        } else if (_mainReferrer == _referrer) {
            users[_mainReferrer].x4Positions[_level].directSales++;
        } else {
            member.x4Positions[_level].reEntryCheck = 1;
        }

        referrerPlaceX4(_addr, _referrer, _level, false);
    }

    function referrerPlaceX4(
        address _addr,
        address _referrer,
        uint8 _level,
        bool passup
    ) internal {
        X4 storage member = users[_addr].x4Positions[_level];
        X4 storage position = users[_referrer].x4Positions[_level];

        if (position.placementFirstLevel.length < 2) {
            if (position.placementFirstLevel.length == 0) {
                member.placementSide = 1;
            } else {
                member.placementSide = 2;
            }

            member.placedUnder = _referrer;
            position.placementFirstLevel.push(_addr);

            if (_referrer != idToAddress[1]) {
                position.passup++;
            }

            positionPlaceLastLevelX4(
                _addr,
                _referrer,
                position.placedUnder,
                position.placementSide,
                _level
            );
        } else {
            if (position.placementLastLevel == 0) {
                member.placementSide = 1;
                member.placedUnder = position.placementFirstLevel[0];
                position.placementLastLevel += 1;
            } else if ((position.placementLastLevel & 2) == 0) {
                member.placementSide = 2;
                member.placedUnder = position.placementFirstLevel[0];
                position.placementLastLevel += 2;
            } else if ((position.placementLastLevel & 4) == 0) {
                member.placementSide = 1;
                member.placedUnder = position.placementFirstLevel[1];
                position.placementLastLevel += 4;
            } else {
                member.placementSide = 2;
                member.placedUnder = position.placementFirstLevel[1];
                position.placementLastLevel += 8;
            }

            if (member.placedUnder != idToAddress[1]) {
                users[member.placedUnder].x4Positions[_level]
                    .placementFirstLevel
                    .push(_addr);
            }
        }

        if ((position.placementLastLevel & 15) == 15) {
            emit Cycle(_referrer, _addr, 2, _level);

            position.placementFirstLevel = new address[](0);
            position.placementLastLevel = 0;
            position.cycles++;

            if (_referrer != idToAddress[1]) {
                position.cycle++;

                referrerPlaceX4(_referrer, position.referrer, _level, true);
            }
        }

        emit PlacementX4(
            _addr,
            _referrer,
            _level,
            member.placementSide,
            member.placedUnder,
            passup
        );
    }

    function positionPlaceLastLevelX4(
        address _addr,
        address _referrer,
        address _position,
        uint8 _placementSide,
        uint8 _level
    ) internal {
        X4 storage position = users[_position].x4Positions[_level];

        if (position.placementSide == 0 && _referrer == idToAddress[1]) {
            return;
        }

        if (_placementSide == 1) {
            if ((position.placementLastLevel & 1) == 0) {
                position.placementLastLevel += 1;
            } else {
                position.placementLastLevel += 2;
            }
        } else {
            if ((position.placementLastLevel & 4) == 0) {
                position.placementLastLevel += 4;
            } else {
                position.placementLastLevel += 8;
            }
        }

        if ((position.placementLastLevel & 15) == 15) {
            emit Cycle(_position, _addr, 2, _level);

            position.placementFirstLevel = new address[](0);
            position.placementLastLevel = 0;
            position.cycles++;

            if (_position != idToAddress[1]) {
                position.cycle++;

                referrerPlaceX4(_position, position.referrer, _level, true);
            }
        }
    }

    function findActiveReferrer(
        address _addr,
        address _referrer,
        uint8 _matrix,
        uint8 _level,
        bool _emit
    ) internal returns (address) {
        address referrerAddress = _referrer;

        while (true) {
            if (users[referrerAddress].activeLevel[_matrix] >= _level) {
                return referrerAddress;
            }
            referrerAddress = users[referrerAddress].referrer;
            if (_emit) {
                emit FundsPassup(referrerAddress, _addr, (_matrix + 1), _level);
            }
        }
    }

    function handleReEntryX3(address _addr, uint8 _level) internal {
        X3 storage member = users[_addr].x3Positions[_level];
        bool reentry = false;

        member.reEntryCheck++;

        if (member.reEntryCheck >= REENTRY_REQ) {
            address referrer = users[_addr].referrer;

            if (users[referrer].activeLevel[0] >= _level) {
                member.reEntryCheck = 0;
                reentry = true;
            } else {
                referrer = findActiveReferrer(
                    _addr,
                    referrer,
                    0,
                    _level,
                    false
                );

                if (
                    member.referrer != referrer &&
                    users[referrer].activeLevel[0] >= _level
                ) {
                    reentry = true;
                }
            }

            if (reentry) {
                member.referrer = referrer;

                emit PlacementReEntry(referrer, _addr, 1, _level);
            }
        }
    }

    function handleReEntryX4(address _addr, uint8 _level) internal {
        X4 storage member = users[_addr].x4Positions[_level];
        bool reentry = false;

        member.reEntryCheck++;

        if (member.reEntryCheck >= REENTRY_REQ) {
            address referrer = users[_addr].referrer;

            if (users[referrer].activeLevel[1] >= _level) {
                member.reEntryCheck = 0;
                member.referrer = referrer;
                reentry = true;
            } else {
                address active_referrer =
                    findActiveReferrer(_addr, referrer, 1, _level, false);

                if (
                    member.referrer != active_referrer &&
                    users[active_referrer].activeLevel[1] >= _level
                ) {
                    member.referrer = active_referrer;
                    reentry = true;
                }
            }

            if (reentry) {
                emit PlacementReEntry(member.referrer, _addr, 2, _level);
            }
        }
    }

    function findPayoutReceiver(
        address _addr,
        uint8 _matrix,
        uint8 _level
    ) internal returns (address) {
        address from;
        address receiver;

        if (_matrix == 0) {
            receiver = users[_addr].x3Positions[_level].referrer;

            while (true) {
                X3 storage member = users[receiver].x3Positions[_level];

                if (member.passup == 0) {
                    return receiver;
                }

                member.passup--;
                from = receiver;
                receiver = member.referrer;

                if (_level > 1 && member.reEntryCheck > 0) {
                    handleReEntryX3(from, _level);
                }
            }
        } else {
            receiver = users[_addr].x4Positions[_level].referrer;

            while (true) {
                X4 storage member = users[receiver].x4Positions[_level];

                if (member.passup == 0 && member.cycle == 0) {
                    return receiver;
                }

                if (member.passup > 0) {
                    member.passup--;
                    receiver = member.placedUnder;
                } else {
                    member.cycle--;
                    from = receiver;
                    receiver = member.referrer;

                    if (_level > 1 && member.reEntryCheck > 0) {
                        handleReEntryX4(from, _level);
                    }
                }
            }
        }
    }

    function handlePayout(
        address _addr,
        uint8 _matrix,
        uint8 _level
    ) internal {
        address receiver = findPayoutReceiver(_addr, _matrix, _level);

        emit FundsPayout(receiver, _addr, (_matrix + 1), _level);

        uint256 cost = levelCost[_level];
        
        bool success = address(uint160(receiver)).send(cost);
        if (!success) {
            uint256 balance = address(this).balance;
            return address(uint160(idToAddress[1])).transfer(balance);
        }
        require(success, "Transfer Failed");
    }

    function getAffiliateWallet(uint32 memberId)
        external
        view
        returns (address)
    {
        return idToAddress[memberId];
    }

    function usersX3Matrix(address _addr, uint8 _level)
        external
        view
        returns (
            uint32,
            uint16,
            uint8,
            uint8,
            uint8,
            address
        )
    {
        return (
            users[_addr].x3Positions[_level].directSales,
            users[_addr].x3Positions[_level].cycles,
            users[_addr].x3Positions[_level].passup,
            users[_addr].x3Positions[_level].reEntryCheck,
            users[_addr].x3Positions[_level].placement,
            users[_addr].x3Positions[_level].referrer
        );
    }

    function usersX4Matrix(address _addr, uint8 _level)
        external
        view
        returns (
            uint32,
            uint16,
            uint8,
            uint8,
            address
        )
    {
        return (
            users[_addr].x4Positions[_level].directSales,
            users[_addr].x4Positions[_level].cycles,
            users[_addr].x4Positions[_level].passup,
            users[_addr].x4Positions[_level].reEntryCheck,
            users[_addr].x4Positions[_level].referrer
        );
    }

    function usersX4MatrixPlacements(address _addr, uint8 _level)
        external
        view
        returns (
            uint8,
            uint8,
            address,
            address[] memory
        )
    {
        return (
            users[_addr].x4Positions[_level].placementLastLevel,
            users[_addr].x4Positions[_level].placementSide,
            users[_addr].x4Positions[_level].placedUnder,
            users[_addr].x4Positions[_level].placementFirstLevel
        );
    }
}
