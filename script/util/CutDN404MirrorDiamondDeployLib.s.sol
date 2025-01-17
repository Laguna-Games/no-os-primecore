// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// forge-ignore: 5574

import {console} from '../../lib/forge-std/src/console.sol';
import {DiamondProxyFacet} from '../../lib/laguna-diamond-foundry/src/diamond/DiamondProxyFacet.sol';
import {LibDeploy} from '../../lib/laguna-diamond-foundry/script/util/LibDeploy.s.sol';
import {CutDN404MirrorDiamond} from '../../src/implementation/CutDN404MirrorDiamond.sol';

library CutDN404MirrorDiamondDeployLib {
    string public constant IMPLEMENTATION_NAME = 'CutDN404MirrorDiamond';

    /// @notice Deploys a new implementation instance
    /// @return implementation The address of the deployed implementation
    function deployNewInstance() internal returns (address implementation) {
        implementation = address(new CutDN404MirrorDiamond());
        console.log(
            string.concat(
                string.concat('Deployed ', IMPLEMENTATION_NAME, ' at: ', LibDeploy.getVM().toString(implementation))
            )
        );
    }

    /// @notice Sets the implementation interface on a diamond
    /// @param diamond The address of the diamond to attach the facet to
    /// @param implementation The address of the implementation
    function setImplementationOnDiamond(address diamond, address implementation) internal {
        DiamondProxyFacet(diamond).setImplementation(implementation);
    }
}
