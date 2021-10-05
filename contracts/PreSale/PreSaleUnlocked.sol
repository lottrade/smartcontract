// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PreSaleLocked.sol";

contract PreSaleUnlocked is PreSaleLocked {
    modifier checkUnlocked() {
        require(block.timestamp > _unlockedTable[20], "PreSale::unlocked: Unlocked is not active");
        _;
    }
    
    constructor(address _busd, address _lott) {
        LOTT = IERC20(_lott);
        BUSD = IERC20(_busd);
    }
    
    function _unlocked(uint256 _amount) private {
        LOTT.transfer(msg.sender, _amount);
        lockedBalances[msg.sender] -= _amount;
        emit UnLocked(msg.sender, _amount);
    }
    
    function unlocked(uint256 _amount) external checkUnlocked {
        uint32 percent = _percentUnlocked();
        uint maxPosibilityUnlocked = percent * _lockedBalances[msg.sender] / 100;
        require(maxPosibilityUnlocked >= _amount, "PreSale::unlocked: Amount more than max posibility unlocked");
        require((_lockedBalances[msg.sender] - lockedBalances[msg.sender]) + _amount <= maxPosibilityUnlocked, "PreSale::unlocked: Amount more than posibility unlocked");
        uint actualBalanceLOTT = LOTT.balanceOf(address(this));
        require(actualBalanceLOTT >= _amount, "PreSale::unlocked: Contract does not have enough money to unlock");
        _unlocked(_amount);
    }
    
    function _percentUnlocked() private view returns(uint32) {
        uint32 percent;
        uint256 timeNow = block.timestamp;
        if (timeNow > _unlockedTable[20] && timeNow < _unlockedTable[30]) {
            percent = 20;
        } else if (timeNow > _unlockedTable[30] && timeNow < _unlockedTable[50]) {
            percent = 50;
        } else {
            percent = 100;
        }
        
        return percent;
    }
}