// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./TokenSaleLocked.sol";
import "../utils/address.sol";

contract TokenSaleUnlocked is TokenSaleLocked {
    using Address for address;
    
    function _checkUnlocked(address _address) private view {
        UnlockedTable
            memory firstMonthUnlockedTable = _firstMonthUnlockedTable();

        uint256 firstTimeLocked = _lockedBalancesFirstTime[_address];
        require(firstTimeLocked > 0 && block.timestamp > firstTimeLocked, "TokenSale::unlocked: Unlocked is not active");

        require(
            block.timestamp >
                firstTimeLocked +
                    (firstMonthUnlockedTable.month * _daysInMonth),
            "TokenSale::unlocked: Unlocked is not active"
        );
    }

    function _firstMonthUnlockedTable()
        private
        view
        returns (UnlockedTable memory)
    {
        uint8 checkMinMonth = _unlockedMonths[0];
        uint8 checkMinMonthIndex = 0;
        for (uint8 i = 0; i < _unlockedMonths.length; i++) {
            if (
                checkMinMonth > _unlockedMonths[i] && _unlockedPercents[i] > 0
            ) {
                checkMinMonth = _unlockedMonths[i];
                checkMinMonthIndex = i;
            }
        }

        return
            UnlockedTable(_unlockedPercents[checkMinMonthIndex], checkMinMonth);
    }

    constructor(address _busd, address _lott, uint256 _maxCap, uint256 _lottPrice, uint8[] memory _percents, uint8[] memory _months) {
        LOTT = IERC20(_lott);
        BUSD = IERC20(_busd);
        _setMaxCap(_maxCap);
        _setLottPrice(_lottPrice);
        _setUnlockedTable(_percents, _months);
    }

    function _unlocked(address _address, uint256 _amount) internal {
        _checkUnlocked(_address);
        uint256 maxPosUnlocked = _calculateMaxPosibilityUnlocked(_address);
        require(
            maxPosUnlocked >= _amount,
            "TokenSale::unlocked: Amount more than max posibility unlocked"
        );
        require(
            (_lockedBalances[_address] - lockedBalances[_address]) +
                _amount <=
                maxPosUnlocked,
            "TokenSale::unlocked: Amount more than posibility unlocked"
        );
        uint256 actualBalanceLOTT = LOTT.balanceOf(address(this));
        require(
            actualBalanceLOTT >= _amount,
            "TokenSale::unlocked: Contract does not have enough money to unlock"
        );
        LOTT.transfer(_address, _amount);
        lockedBalances[_address] -= _amount;
        emit UnLocked(_address, _amount);
    }

    function unlocked(uint256 _amount) external {
        _unlocked(tx.origin, _amount);
    }

    function unlockedForOwner(address _to, uint256 _amount)
        external
        onlyOwnerOrigin
    {
        require(
            !_to.isContract(),
            "TokenSale::lockedForOwner: To address must not be contract address"
        );
        require(
            _to != address(0),
            "TokenSale::lockedForOwner: To address is zero."
        );
        _unlocked(_to, _amount);
    }
    
    function _calculateMaxPosibilityUnlocked(address _address) internal view returns(uint256) {
        uint32 percent = _percentUnlocked(_address);
        
        return  (percent * _lockedBalances[_address]) / 100;
    }

    function _percentUnlocked(address _address) private view returns (uint8) {
        uint8 percent;
        uint8 maxPercent = 100;
        uint256 timeNow = block.timestamp;
        uint256 firstTimeLocked = _lockedBalancesFirstTime[_address];

        uint8 calcPercent = 0;
        bool checkLastMonth = false;
        uint8 lastPercent;
        uint8 lastMonth;
        for (uint8 i = 0; i < _unlockedMonths.length; i++) {
            uint8 unLockedMonth = _unlockedMonths[i];
            uint8 unLockedPercent = _unlockedPercents[i];
            if (
                unLockedPercent > 0 &&
                timeNow >
                firstTimeLocked + (unLockedMonth * _daysInMonth)
            ) {
                calcPercent += unLockedPercent;
                if (i == _unlockedMonths.length - 1) {
                    checkLastMonth = true;
                    lastPercent = unLockedPercent;
                    lastMonth = unLockedMonth;
                }
            }
        }

        if (checkLastMonth && calcPercent < maxPercent) {
            uint8 calcMissingMonth = (maxPercent - calcPercent) / lastPercent;
            for (uint8 i = 1; i <= calcMissingMonth; i++) {
                uint8 nextMonth = lastMonth + i;
                if (timeNow > firstTimeLocked + (nextMonth * _daysInMonth)) {
                    calcPercent += lastPercent;
                }
            }
        }

        percent = calcPercent;

        return percent;
    }
    
    function percentUnlocked() external view returns(uint8) {
        _checkUnlocked(tx.origin);
        return _percentUnlocked(tx.origin);
    }
    
    function maxPosibilityUnlocked() external view returns(uint256) {
        _checkUnlocked(tx.origin);
        return _calculateMaxPosibilityUnlocked(tx.origin);
    }
    
    function posibilityUnlocked() external view returns(uint256) {
        _checkUnlocked(tx.origin);
        if (lockedBalances[tx.origin] > 0) {
            return _calculateMaxPosibilityUnlocked(tx.origin) - (_lockedBalances[tx.origin] - lockedBalances[tx.origin]);
        }
        
        return _calculateMaxPosibilityUnlocked(tx.origin);
    }
}
