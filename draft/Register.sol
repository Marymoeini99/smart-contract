// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Structs.sol";

contract Register {
    address public financialManager;
    address public factoryAddress;

    mapping(address => Manufactury) theManufactury;
    mapping(uint => Branch) branches;
    mapping(uint => _3pl) _3pls;
    mapping(uint => Retailer) _retailers;
    mapping(uint => Order) _orders;
    mapping(uint => Product) _products;

    modifier OnlyfinancialManager {
        require(msg.sender == financialManager, "You don't have access");
        _;
    }

    modifier OnlyValid3pl(uint _orderId) {
        _OnlyValid3pl(_orderId);
        _;
    }

    modifier OnlyValidBranch(uint _orderId) {
        _OnlyValidBranch(_orderId);
        _;
    }

    event ManufacturyAdded (address Manufactury, address indexed FinancialManager);
    event BranchAdded (uint ID, address BranchWallet);
    event BranchAdded (uint ID, address[] Trusted3pls);
    event RetailerAdded (uint ID, address wallet);
    event RetailerUpdated (uint ID, address wallet);
    event _3plAdded (uint ID, address wallet, trusted_3pl Who);
    event _3plAssigned (uint ID, uint BranchID);
    event _3plUpdated (uint ID, address wallet, trusted_3pl Who);
    event ProductAdded (uint ID, uint Price, uint InStock);
    event ProductUpdated (uint ID, uint Price, uint InStock);
    event ManufacturyUpdated (address Manufactury);
    event BranchUpdated (uint ID);
    event BranchUpdated (uint ID, uint remainingOrderLimit);
    event OrderCountAccepted (uint ID, address _3pl);
    event PaymentDone (address recipient, uint amount);

    constructor (/*address _financialManager*/) {
            financialManager = msg.sender;
            addManufactury(financialManager);
    }

    function addManufactury(address _theManufactury) public OnlyfinancialManager {
        factoryAddress = _theManufactury;
        emit ManufacturyAdded(factoryAddress, msg.sender);
    }

    function addBranch(
        uint _bId, 
        uint _bMinOrder,
        uint _bMaxOrder,
        address _bAddress, 
        uint _bOrderLimit, 
        string memory _bLocation
        ) external OnlyfinancialManager {
            Manufactury storage _theManufactury = theManufactury[factoryAddress];
            Branch storage _branch = _theManufactury.validBranch[_bId];
            require(_branch.id != _bId, "Already declared this ");
            _branch.id = _bId;
            _branch.minOrderVolume = _bMinOrder;
            _branch.maxOrderVolume = _bMaxOrder;
            _branch.wallet = _bAddress;
            _branch.received = false;
            // _branch.orderCount = 0;
            _branch.orderLimit = _bOrderLimit;
            _branch.location = _bLocation;

            emit BranchAdded(_bId, _bAddress);
    }
    
    function updateBranch(
        uint _bId, 
        uint _bMinOrder,
        uint _bMaxOrder,
        address _bAddress, 
        uint _bOrderLimit, 
        string memory _bLocation
        ) external OnlyfinancialManager {
            Manufactury storage _theManufactury = theManufactury[factoryAddress];
            Branch storage _branch = _theManufactury.validBranch[_bId];
            require(_branch.id == _bId, "This branch does not exist");
            _branch.id = _bId;
            _branch.minOrderVolume = _bMinOrder;
            _branch.maxOrderVolume = _bMaxOrder;
            _branch.wallet = _bAddress;
            _branch.received = false;
            _branch.orderLimit = _bOrderLimit;
            _branch.location = _bLocation;

            emit BranchAdded(_bId, _bAddress);
    }

    function add3pl(
        uint _3plId, 
        address _3plAddress/*,
        trusted_3pl _who*/) 
        external 
        OnlyfinancialManager {
            Manufactury storage _theManufactury = theManufactury[factoryAddress];
            _3pl storage the3pl = _theManufactury.trusted3pl[_3plId];
            require(the3pl.id != _3plId, "Already declared this 3pl");
            the3pl.id = _3plId;
            the3pl.wallet = _3plAddress;
            the3pl.who = trusted_3pl.Manufactury;

            emit _3plAdded(_3plId, _3plAddress, the3pl.who);
    }

    function update3pl(
        uint _3plId, 
        address _3plAddress,
        trusted_3pl _who) 
        external 
        OnlyfinancialManager {
            Manufactury storage _theManufactury = theManufactury[factoryAddress];
            _3pl storage the3pl = _theManufactury.trusted3pl[_3plId];
            require(the3pl.id == _3plId, "This 3pl does not exist");
            the3pl.id = _3plId;
            the3pl.wallet = _3plAddress;
            the3pl.who = _who;

            emit _3plAdded(_3plId, _3plAddress, the3pl.who);
    }

    function addProduct(
        uint _pId,
        uint _pPrice,
        uint _pInStock) 
        external 
        OnlyfinancialManager {
            Manufactury storage _theManufactury = theManufactury[factoryAddress];
            Product storage theProduct = _theManufactury.products[_pId];
            require(theProduct.id != _pId, "Already declared this product");
            theProduct.id = _pId;
            theProduct.price = _pPrice;
            theProduct.inStock = _pInStock;
            emit ProductAdded(_pId, _pPrice, _pInStock);
    }

    function getBranchData(
        uint _bId
        ) 
        public 
        view 
        returns (
            uint, 
            uint, 
            address,
            bool,
            uint, 
            uint, 
            string memory,
            _3pl[] memory) {
                Manufactury storage _theManufactury = theManufactury[factoryAddress];
                Branch storage _branch = _theManufactury.validBranch[_bId];
                _3pl[] memory _the3plsArray = new _3pl[](3);
                for(uint i = 0; i < _the3plsArray.length; i++) {
                    _the3plsArray[i] = get3plData(_branch.trusted3pl[i+1].id);
                }
                return (
                    _branch.minOrderVolume,
                    _branch.maxOrderVolume,
                    _branch.wallet,
                    _branch.received, 
                    _branch.orderCount,
                    _branch.orderLimit, 
                    _branch.location, 
                    _the3plsArray
                    );
    }

    function assign3pl(uint _bId, uint _3plId) public {
        Manufactury storage _theManufactury = theManufactury[factoryAddress];
        Branch storage _branch = _theManufactury.validBranch[_bId];
        _3pl storage the3pl = _theManufactury.trusted3pl[_3plId];
        the3pl.who = trusted_3pl.Branch;

        _branch.trusted3pl[_3plId] = get3plData(_3plId);
        
        emit _3plAssigned(_3plId, _bId);
    }

    function get3plData(uint _3plId) public view returns (_3pl memory) {
        Manufactury storage _theManufactury = theManufactury[factoryAddress];
        _3pl storage _the3pl = _theManufactury.trusted3pl[_3plId];
        return _the3pl;
    }

    function getProductData(uint _pId) public view returns (Product memory) {
        Manufactury storage _theManufactury = theManufactury[factoryAddress];
        Product storage _theProduct = _theManufactury.products[_pId];
        return _theProduct;
    }

    function takeOrder(uint _preOrderId) public OnlyfinancialManager {
        Order storage theOrder = _orders[_preOrderId];
        theOrder.id = uint(keccak256(abi.encodePacked(_preOrderId, block.timestamp)));
        theOrder.status = OrderStatus.Pending;
    }

    function processOrder(uint _id) public OnlyfinancialManager {
        Order storage theOrder = _orders[_id];
        theOrder.status = OrderStatus.Accepted;
    }

    function assignTo3pl(uint _orderId, address _3plAddress) public OnlyfinancialManager {
        Order storage theOrder = _orders[_orderId];
        theOrder.the3pl.wallet = _3plAddress;
    }

    function compareOrder(uint _orderId, uint _oProducts) public OnlyfinancialManager view returns (bool){
        Order storage theOrder = _orders[_orderId];
        return (theOrder.orderVolume == _oProducts) ? true : false;
    }

    function deliveredTo3pl(uint _orderId) public OnlyValid3pl(_orderId) {
        Order storage theOrder = _orders[_orderId];
        theOrder.the3pl.received = true;
        uint firstDeposit = (theOrder.orderValue * 30) / 100;
        // theOrder.orderValue -= theOrder.orderValue.mul(30).div(100);
        _pay(theOrder.the3pl.wallet, firstDeposit);
        theOrder.status = OrderStatus.Delivering;

        emit OrderCountAccepted(_orderId, theOrder.the3pl.wallet);
    }

    function deliveredToBranch(uint _orderId, uint _receivedProducts) public OnlyValidBranch(_orderId) {
        Order storage theOrder = _orders[_orderId];
        require(compareOrder(_orderId, _receivedProducts), "Products count is not correct");
        theOrder.theBranch.received = true;
        uint fullPayOff = (theOrder.orderValue * 70) / 100;
        _pay(theOrder.the3pl.wallet, fullPayOff);
        theOrder.status = OrderStatus.Fulfilled;

        emit OrderCountAccepted(_orderId, theOrder.theBranch.wallet);
    }

    function _pay(address recipient, uint amount) internal {
        payable(recipient).transfer(amount);

        emit PaymentDone(recipient, amount);
    }

    function _OnlyValid3pl(uint _orderId) internal view {
        Order storage theOrder = _orders[_orderId];
        require(msg.sender == theOrder.the3pl.wallet, "The 3pl not valid");
    }

    function _OnlyValidBranch(uint _orderId) internal view {
        Order storage theOrder = _orders[_orderId];
        require(msg.sender == theOrder.theBranch.wallet, "The branch not valid");
    }

    receive() external payable { }
}
