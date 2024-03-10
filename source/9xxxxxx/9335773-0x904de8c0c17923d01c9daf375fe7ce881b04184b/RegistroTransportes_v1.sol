pragma solidity ^0.4.24;

library SafeMath 
{
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) 
    {
        if (_a == 0) 
        {
          return 0;

        }

        c = _a * _b;

        require(c / _a == _b);

        return c;
        
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) 
    {
        require(_b != 0); 

        return _a / _b;
        
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) 
    {
        require(_a >= _b); 

        return _a - _b;
        
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) 
    {
        c = _a + _b;

        require(c >= _a);

        return c;
        
    }

}

contract Ownable 
{
    address public owner;

    event OwnershipRenounced( address indexed previousOwner );

    event OwnershipTransferred( address indexed previousOwner, address indexed newOwner );

    constructor() public 
    {
        owner = msg.sender;
        
    }
 
    function transferOwnership(address _newOwner) public onlyOwner 
    {
        _transferOwnership(_newOwner);
        
    }
 
    function _transferOwnership(address _newOwner) internal 
    {
        require(_newOwner != address(0));
    
        emit OwnershipTransferred(owner, _newOwner);
    
        owner = _newOwner;
        
    }
 
    modifier onlyOwner() 
    {
        require(msg.sender == owner);
        _;
        
    }
}

contract RegistroTransportes_v1 is Ownable
{
	using SafeMath for uint256;
	
	struct ListaOperaciones
    {
		uint     idMovimiento;
		uint256  idCliente;
        string   cliente;
        uint256  unidad;
        uint256  idChofer;
        string   chofer;
        string   fecha;
        string   evento;
        
	}

    mapping (uint => ListaOperaciones) private Operaciones;
    
    mapping (uint => bool) private OperacionesRegistradas;

    event registramovimiento (uint, uint256, string, uint256, uint256, string, string, string);
    
    event Pause();

    event Unpause();

    bool public paused = false;

    function contractAddress() public view returns(address)
    { 
        return address(this); 
        
    }
    
    function RegistraMovimiento(uint _idMovimiento, uint256 _idCliente, string _cliente, uint256 _unidad, uint256 _idChofer, string _chofer, string _fecha, string _evento) public onlyOwner
    {
        require(!MovimientoRegistrado(_idMovimiento));
        
        ListaOperaciones storage lista = Operaciones[_idMovimiento];
        
        lista.idMovimiento = _idMovimiento;
        lista.idCliente = _idCliente;
        lista.cliente = _cliente;
        lista.unidad = _unidad;
        lista.idCliente = _idChofer;
        lista.chofer = _chofer;
        lista.fecha = _fecha;
        lista.evento = _evento;
        
        OperacionesRegistradas[_idMovimiento] = true;
        
        emit registramovimiento(lista.idMovimiento, lista.idCliente, lista.cliente, lista.unidad, lista.idCliente, lista.chofer, lista.fecha, lista.evento);

    }
    
    function ConsultaMovimiento(uint _idMovimiento) public view returns (uint, uint256, string, uint256, uint256, string, string, string)
    {
        require(_idMovimiento != 0, 'Escriba un movimiento valido');
        
        require(MovimientoRegistrado(_idMovimiento));
        
        ListaOperaciones memory lista = Operaciones[_idMovimiento];
        
        return (lista.idMovimiento, 
                lista.idCliente, 
                lista.cliente, 
                lista.unidad, 
                lista.idCliente, 
                lista.chofer, 
                lista.fecha, 
                lista.evento);
                
    }
    
    function MovimientoRegistrado(uint _idMovimiento) private view returns (bool)
    {
        return OperacionesRegistradas[_idMovimiento];
        
    }
    
    function pause() public onlyOwner whenNotPaused 
    { 
        paused = true;
        
        emit Pause(); 
        
    }

    function unpause() public onlyOwner whenPaused 
    { 
        paused = false; 
        
        emit Unpause(); 
        
    }

    function destroyContract() public onlyOwner 
    { 
        selfdestruct(owner); 
        
    }

    modifier whenNotPaused() 
    { 
        require(!paused); 
        _; 
        
    }
    
    modifier whenPaused() 
    { 
        require(paused); 
        _; 
        
    }
    
}
