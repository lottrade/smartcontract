// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../utils/address.sol";

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool response);
}

interface ILiquidityRestrictor {
    function assureByAgent(
        address token,
        address from,
        address to
    ) external returns (bool allow, string memory message);

    function assureLiquidityRestrictions(address from, address to)
        external
        returns (bool allow, string memory message);
}

contract LOTTBEP20Token is ERC20, Ownable {
    using Address for address;
    
    constructor(uint256 initialSupply) ERC20("LOT.TRADE LOTT token", "LOTT") {
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
    ILiquidityRestrictor public liquidityRestrictor =
        ILiquidityRestrictor(0xeD1261C063563Ff916d7b1689Ac7Ef68177867F2);

    bool public antisnipeEnabled = true;
    bool public liquidityRestrictionEnabled = true;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0) || to == address(0)) return;
        if (
            liquidityRestrictionEnabled &&
            address(liquidityRestrictor) != address(0)
        ) {
            (bool allow, string memory message) = liquidityRestrictor
                .assureLiquidityRestrictions(from, to);
            require(allow, message);
        }

        if (antisnipeEnabled && address(antisnipe) != address(0)) {
            require(antisnipe.assureCanTransfer(msg.sender, from, to, amount));
        }
    }

    function setAntisnipeDisable() external onlyOwner {
        require(antisnipeEnabled);
        antisnipeEnabled = false;
    }

    function setLiquidityRestrictorDisable() external onlyOwner {
        require(liquidityRestrictionEnabled);
        liquidityRestrictionEnabled = false;
    }
    
    function setAntisnipeContractAddress(address _address) external onlyOwner {
        require(
            _address.isContract(),
            "LottCore::setAntisnipeContractAddress: Address must be contract address"
        );
        antisnipe = IAntisnipe(_address);
    }
    
    function setLiquidityRestrictorContractAddress(address _address) external onlyOwner {
        require(
            _address.isContract(),
            "LottCore::setAntisnipeContractAddress: Address must be contract address"
        );
        liquidityRestrictor = ILiquidityRestrictor(_address);
    }
}
