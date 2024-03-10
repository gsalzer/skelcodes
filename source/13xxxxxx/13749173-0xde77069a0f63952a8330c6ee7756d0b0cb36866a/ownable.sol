// SPDX-License-Identifier: MIT
pragma solidity =0.8.8;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);}
    function _msgData() internal view virtual returns (bytes memory) {this;
    return msg.data;}}
contract Ownable is Context {
    address private _owner;
    address internal _distributor;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);}
    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");_;}
    modifier distributors() {
    require(_distributor == msg.sender, "Caller is not fee distributor");_;}
    function owner() public view returns (address) {
    return _owner;}
    function distributor() internal view returns (address) {
    return _distributor;}
    function setDistributor(address account) external onlyOwner {
    require (_distributor == address(0));
    _distributor = account;}
    function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);}}
