// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
// forge-ignore: 5574

import {console} from '../../lib/forge-std/src/console.sol';
import {IDiamondCut} from '../../lib/laguna-diamond-foundry/src/interfaces/IDiamondCut.sol';
import {LibDeploy} from '../../lib/laguna-diamond-foundry/script/util/LibDeploy.s.sol';
import {DN404AdminFacet} from '../../src/facets/DN404AdminFacet.sol';

library DN404AdminFacetDeployLib {
    string public constant FACET_NAME = 'DN404AdminFacet';

    /// @notice Returns the list of public selectors belonging to the DN404AdminFacet
    /// @return selectors List of selectors
    function getSelectorList() internal pure returns (bytes4[] memory selectors) {
        selectors = new bytes4[](27);
        selectors[0] = DN404AdminFacet.initializeDN404.selector;
        selectors[1] = DN404AdminFacet.setPresaleContract.selector;
        selectors[2] = DN404AdminFacet.getPresaleContract.selector;
        selectors[3] = DN404AdminFacet.setUniswapRouter.selector;
        selectors[4] = DN404AdminFacet.getUniswapRouter.selector;
        selectors[5] = DN404AdminFacet.addToWhitelist.selector;
        selectors[6] = DN404AdminFacet.removeFromWhitelist.selector;
        selectors[7] = DN404AdminFacet.isWhitelisted.selector;
        selectors[8] = DN404AdminFacet.getWhitelistedAddresses.selector;
        selectors[9] = DN404AdminFacet.setRerollThreshold.selector;
        selectors[10] = DN404AdminFacet.getRerollThreshold.selector;
        selectors[11] = DN404AdminFacet.setTreasuryAddress.selector;
        selectors[12] = DN404AdminFacet.getTreasuryAddress.selector;
        selectors[13] = DN404AdminFacet.setTreasuryFeePercentage.selector;
        selectors[14] = DN404AdminFacet.getTreasuryFeePercentage.selector;
        selectors[15] = DN404AdminFacet.mint.selector;
        selectors[16] = DN404AdminFacet.getUserNFTsBatch.selector;
        selectors[17] = DN404AdminFacet.getPrimecoreData.selector;
        selectors[18] = DN404AdminFacet.implementsDN404.selector;
        selectors[19] = DN404AdminFacet.setPoolFeeTier.selector;
        selectors[20] = DN404AdminFacet.getPoolFeeTier.selector;
        selectors[21] = DN404AdminFacet.setPoolAddress.selector;
        selectors[22] = DN404AdminFacet.getPoolAddress.selector;
        selectors[23] = DN404AdminFacet.getRerollCost.selector;
        selectors[24] = DN404AdminFacet.setBaseURI.selector;
        selectors[25] = DN404AdminFacet.setContractURI.selector;
        selectors[26] = DN404AdminFacet.setTokenURI.selector;
    }

    /// @notice Creates a FacetCut object for attaching a facet to a Diamond
    /// @dev This method is exposed to allow multiple cuts to be bundled in one call
    /// @param facet The address of the facet to attach
    /// @return cut The `Add` FacetCut object
    function generateFacetCut(address facet) internal pure returns (IDiamondCut.FacetCut memory cut) {
        cut = LibDeploy.facetCutGenerator(facet, getSelectorList());
    }

    /// @notice Deploys a new facet instance
    /// @return facet The address of the deployed facet
    function deployNewInstance() internal returns (address facet) {
        facet = address(new DN404AdminFacet());
        console.log(string.concat(string.concat('Deployed ', FACET_NAME, ' at: ', LibDeploy.getVM().toString(facet))));
    }

    /// @notice Attaches a DN404AdminFacet to a diamond
    function attachFacetToDiamond(address diamond, address facet) internal {
        LibDeploy.cutFacetOntoDiamond(FACET_NAME, generateFacetCut(facet), diamond);
    }

    /// @notice Removes the DN404AdminFacet from a Diamond
    /// @dev NOTE: This is a greedy cleanup - use it to nuke all of an old facet (even if the old version has extra
    /// deprecated endpoints). If you are un-sure please review this code carefully before using it!
    function removeFacetFromDiamond(address diamond) internal {
        LibDeploy.cutFacetOffOfDiamond(FACET_NAME, getSelectorList(), diamond);
    }
}
