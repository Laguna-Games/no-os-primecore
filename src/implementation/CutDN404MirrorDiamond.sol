// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CutDiamond} from '../../lib/laguna-diamond-foundry/src/diamond/CutDiamond.sol';
import {DN404MirrorFragment} from './DN404MirrorFragment.sol';

/// @title Cut DN404 Diamond
/// @notice This is a dummy "implementation" contract for ERC-1967 compatibility,
/// @notice this interface is used by block explorers to generate the UI interface.
/// @dev adapted from https://github.com/zdenham/diamond-etherscan?tab=readme-ov-file
contract CutDN404MirrorDiamond is CutDiamond, DN404MirrorFragment {

}
