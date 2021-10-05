// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PreSaleBase is Ownable {
    uint256 internal _maxCap = 10000000000000000000000000 wei;
    uint32 internal _startDate = 1633046400;
    uint32 internal _finishDate = 1638316799;
    uint internal _lottPrice = 50000000000000000 wei;
    uint internal _minPurchase = 500000000000000000000 wei;
    
    IERC20 public LOTT;
    IERC20 public BUSD;

    mapping(address => uint256) internal lockedBalances;
    mapping(address => uint256) internal _lockedBalances;
    mapping(uint8 => uint32) internal _unlockedTable;
    address[] internal _lockedWallets;
    
    event Locked(address indexed lockedAddress, uint256 amount);
    event UnLocked(address indexed unlockedAddress, uint256 amount);
    
    constructor() {
        _unlockedTable[20] = 1631103301;
        _unlockedTable[30] = 1659312000;
        _unlockedTable[50] = 1667260800;
    }
    
    modifier checkTime(uint32 _date) {
        require(block.timestamp < _date, "PreSale:: Date.now more than date");
        _;
    }
    
    function maxCap() external view returns(uint256) {
        return _maxCap;
    }
    
    function startDate() external view returns(uint256) {
        return _startDate;
    }
    
    function finishDate() external view returns(uint256) {
        return _finishDate;
    }
    
    function lottPrice() external view returns(uint) {
        return _lottPrice;
    }
    
    function minPurchase() external view returns(uint) {
        return _minPurchase;
    }
    
    function setUnlockedTable(uint8 _percent, uint32 _date) external onlyOwner checkTime(_date) {
        require(_percent == 20 || _percent == 30 || _percent == 50, "PreSale::setUnlockedTable: Percent must be 20,30,50");
        require(block.timestamp < _date, "PreSale::setUnlockedTable: Date must be more than current date");
        _unlockedTable[_percent] = _date;
    }
    
    function getUnlockedTableTime(uint8 _percent) external view returns (uint256) {
        return _unlockedTable[_percent];
    }
    
    function setMaxCap(uint256 _capital) external onlyOwner returns(bool) {
        require(_maxCap > 0, "PreSale::setMaxCap: MaxCap must be more 0");
        _maxCap = _capital;
        return true;
    }
    
    function setStartDate(uint32 _date) external onlyOwner checkTime(_date) returns(bool) {
        _startDate = _date;
        return true;
    }
    
    function setFinishDate(uint32 _date) external onlyOwner checkTime(_date) returns(bool) {
        _finishDate = _date;
        return true;
    }
    
    function setLottPrice(uint _price) external onlyOwner returns(bool) {
        require(_price > 0, "PreSale::setLottPrice: LottPrice must be more 0");
        _lottPrice = _price;
        return true;
    }
    
    function setMinPurchase(uint _value) external onlyOwner returns(bool) {
        require(_value > 0, "PreSale::setMinPurchase: MinPurchase must be more 0");
        _minPurchase = _value;
        return true;
    }
    
    function burn() external onlyOwner {
        require(block.timestamp > _finishDate, "PreSale::burn: Burn must be after finish pre sale");
        LOTT.transfer(address(LOTT), _maxCap);
    }
    
    function withdraw(address _to, uint256 _amount) external onlyOwner {
        BUSD.transfer(_to, _amount);
    }
}