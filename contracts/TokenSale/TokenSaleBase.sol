// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenSaleBase is Ownable {
    uint256 internal _maxCap;
    uint32 internal _startDate;
    uint32 internal _finishDate = 2551086801;
    uint256 internal _lottPrice;
    uint256 internal _minPurchase;

    IERC20 public LOTT;
    IERC20 public BUSD;

    mapping(address => uint256) internal lockedBalances;
    mapping(address => uint256) internal _lockedBalances;
    mapping(address => uint256) internal _lockedBalancesFirstTime;
    address[] internal _lockedWallets;
    uint8[] internal _unlockedPercents;
    uint8[] internal _unlockedMonths;
    uint256 internal constant _daysInMonth = 30 days;

    event Locked(address indexed lockedAddress, uint256 amount);
    event UnLocked(address indexed unlockedAddress, uint256 amount);
    
    struct UnlockedTable {
        uint8 percent;
        uint8 month;
    }

    modifier checkTime(uint32 _date) {
        require(block.timestamp < _date, "TokenSale:: Date.now more than date");
        _;
    }
    
    modifier onlyOwnerOrigin() {
        require(owner() == tx.origin, "Ownable: caller is not the owner");
        _;
    }

    function maxCap() external view returns (uint256) {
        return _maxCap;
    }

    function startDate() external view returns (uint256) {
        return _startDate;
    }

    function finishDate() external view returns (uint256) {
        return _finishDate;
    }

    function lottPrice() external view returns (uint256) {
        return _lottPrice;
    }

    function minPurchase() external view returns (uint256) {
        return _minPurchase;
    }

    function setUnlockedTable(uint8[] memory _percents, uint8[] memory _months)
        external
        onlyOwner returns(bool)
    {
       return _setUnlockedTable(_percents, _months);
    }
    
    function _setUnlockedTable(uint8[] memory _percents, uint8[] memory _months) internal returns(bool) {
        require(_percents.length == _months.length);
        require(_percents.length <= 100);
        _unlockedPercents = new uint8[](_percents.length);
        _unlockedMonths = new uint8[](_percents.length);
        for (uint256 i = 0; i < _percents.length; i++) {
            uint8 percent = _percents[i];
            uint8 month = _months[i];
            require(
                month >= 1,
                "TokenSale::setUnlockedTable: Month: must be more or equel 1"
            );
            require(
                percent >= 0,
                "TokenSale::setUnlockedTable: Percent: must be more or equel 0"
            );
            _unlockedPercents[i] = percent;
            _unlockedMonths[i] = month;
        }
        
        return true;
    }

    function getUnlockedTableTimeByMonth(uint8 _month) external view returns (uint8) {
        uint8 index;
        for (uint8 i = 0; i < _unlockedMonths.length; i++) {
            if (_month == _unlockedMonths[i]) index = i;
        }
        require(
            index >= 0,
            "TokenSale::getUnlockedTableTime: Unlocked percent by this month not found"
        );
        return _unlockedPercents[index];
    }
    
    function getUnlockedTableTime()
        external
        view
        returns (uint8[] memory months, uint8[] memory pecents)
    {
        return (_unlockedMonths, _unlockedPercents);
    }

    function setMaxCap(uint256 _capital) external onlyOwner returns (bool) {
        return _setMaxCap(_capital);
    }
    
    function _setMaxCap(uint256 _capital) internal returns(bool) {
        require(_capital > 0, "TokenSale::setMaxCap: MaxCap must be more 0");
        _maxCap = _capital;
        return true;
    }

    function setStartDate(uint32 _date)
        external
        onlyOwner
        checkTime(_date)
        returns (bool)
    {
        _startDate = _date;
        return true;
    }

    function setFinishDate(uint32 _date)
        external
        onlyOwner
        checkTime(_date)
        returns (bool)
    {
        _finishDate = _date;
        return true;
    }

    function setLottPrice(uint256 _price) external onlyOwner returns (bool) {
        return _setLottPrice(_price);
    }
    
    function _setLottPrice(uint256 _price) internal returns (bool) {
        require(
            _price > 0,
            "TokenSale::setLottPrice: LottPrice must be more 0"
        );
        _lottPrice = _price;
        return true;
    }

    function setMinPurchase(uint256 _value) external onlyOwner returns (bool) {
        require(
            _value > 0,
            "TokenSale::setMinPurchase: MinPurchase must be more 0"
        );
        _minPurchase = _value;
        return true;
    }

    function burn(address _to) external onlyOwner {
        LOTT.transfer(_to, _maxCap);
    }

    function withdraw(address _to, uint256 _amount) external onlyOwner {
        BUSD.transfer(_to, _amount);
    }
}
