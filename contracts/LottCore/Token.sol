// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool response);
}

contract LOTTBEP20Token is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("LOT LOTT token", "LOTT") {
        _mint(msg.sender, initialSupply);
    }

    function multisend(address[] memory to, uint256[] memory values)
        external
        onlyOwner
        returns (uint256)
    {
        require(to.length == values.length);
        require(to.length < 100);
        for (uint256 i; i < to.length; i++) {
            transfer(to[i], values[i]);
        }
        return (to.length);
    }

    function burnTokens(uint256 amount)
        external
        onlyOwner
        returns (bool success)
    {
        _burn(msg.sender, amount);
        return true;
    }

    IAntisnipe public antisnipe =
        IAntisnipe(0x2E5dDfb5F950fd98fb159E1FA9ABc8DB12DCcFCf);

    bool public antisnipeEnabled = true;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (antisnipeEnabled && address(antisnipe) != address(0)) {
            require(antisnipe.assureCanTransfer(msg.sender, from, to, amount));
        }
    }

    function setAntisnipeDisable() external onlyOwner {
        require(antisnipeEnabled);
        antisnipeEnabled = false;
    }
}
