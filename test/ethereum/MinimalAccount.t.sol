// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../../src/ethereum/MinimalAccount.sol";
import {DeployMinimal} from "../../script/DeployMinimal.s.sol";
import {Helper} from "../../script/Helper.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint, MessageHashUtils} from "../../script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MinimalTest is Test {
    using MessageHashUtils for bytes32;

    Helper helper;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    address randomUser = makeAddr("randomUser");

    uint256 constant AMOUNT = 1e18;

    function setUp() public {
        DeployMinimal deployMinimal = new DeployMinimal();
        (helper, minimalAccount) = deployMinimal.deployMinimalAccount();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    //USDC mint
    //msg.sender
    //approve some amount
    //USDC contract
    //come from the entryPoint

    function testOwnerCanExecuteCommands() public {
        //Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        //Act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);

        //Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testOtherThanOwnerCantExecuteCommands() public {
        //Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        //Act
        vm.prank(randomUser);
        vm.expectRevert(
            MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector
        );
        minimalAccount.execute(dest, value, functionData);
    }

    function testRecoverSignedOp() public {
        //Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        bytes memory executeCallData = abi.encodeWithSelector( // It says that to EntryPoint contract to Our Contract to call USDC
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOp
            .generatedSignedUserOps(
                executeCallData,
                helper.getConfig(),
                address(minimalAccount)
            );
        bytes32 userOperationHash = IEntryPoint(helper.getConfig().entryPoint)
            .getUserOpHash(packedUserOp);

        //Act
        address actualSigner = ECDSA.recover(
            userOperationHash.toEthSignedMessageHash(),
            packedUserOp.signature
        );

        //Assert
        assertEq(actualSigner, minimalAccount.owner());
    }

    // 1. Sign User op
    // 2. Call validate userops
    // 3. Assert the return is correct
    function testValidatorOfUserOps() public {
        //Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        bytes memory executeCallData = abi.encodeWithSelector( // It says that to EntryPoint contract to Our Contract to call USDC
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOp
            .generatedSignedUserOps(
                executeCallData,
                helper.getConfig(),
                address(minimalAccount)
            );
        bytes32 userOperationHash = IEntryPoint(helper.getConfig().entryPoint)
            .getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;

        //Act
        vm.prank(helper.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(
            packedUserOp,
            userOperationHash,
            missingAccountFunds
        );

        //Assert
        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public {
        //Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(
            ERC20Mock.mint.selector,
            address(minimalAccount),
            AMOUNT
        );

        bytes memory executeCallData = abi.encodeWithSelector( // It says that to EntryPoint contract to Our Contract to call USDC
            MinimalAccount.execute.selector,
            dest,
            value,
            functionData
        );
        PackedUserOperation memory packedUserOp = sendPackedUserOp
            .generatedSignedUserOps(
                executeCallData,
                helper.getConfig(),
                address(minimalAccount)
            );
        // bytes32 userOperationHash = IEntryPoint(helper.getConfig().entryPoint)
        //     .getUserOpHash(packedUserOp);

        vm.deal(address(minimalAccount), 1e18);
        address entryPoint = helper.getConfig().entryPoint;

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        //Act
        vm.prank(randomUser, randomUser); // EntryPoint v0.9 requires tx.origin == msg.sender.
        IEntryPoint(entryPoint).handleOps(ops, payable(randomUser)); // payable since random user is going to pay the fees on behalf of ourself for execution.

        //Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
