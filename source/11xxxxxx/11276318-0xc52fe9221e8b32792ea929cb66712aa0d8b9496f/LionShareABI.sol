// SPDX-License-Identifier: BSD-3-Clause

/** 
*                                                                                                                                  
*       ##### /                                                             #######      /                                         
*    ######  /          #                                                 /       ###  #/                                          
*   /#   /  /          ###                                               /         ##  ##                                          
*  /    /  /            #                                                ##        #   ##                                          
*      /  /                                                               ###          ##                                          
*     ## ##           ###        /###    ###  /###         /###          ## ###        ##  /##      /###    ###  /###       /##    
*     ## ##            ###      / ###  /  ###/ #### /     / #### /        ### ###      ## / ###    / ###  /  ###/ #### /   / ###   
*     ## ##             ##     /   ###/    ##   ###/     ##  ###/           ### ###    ##/   ###  /   ###/    ##   ###/   /   ###  
*     ## ##             ##    ##    ##     ##    ##   k ####                  ### /##  ##     ## ##    ##     ##         ##    ### 
*     ## ##             ##    ##    ##     ##    ##   a   ###                   #/ /## ##     ## ##    ##     ##         ########  
*     #  ##             ##    ##    ##     ##    ##   i     ###                  #/ ## ##     ## ##    ##     ##         #######   
*        /              ##    ##    ##     ##    ##   z       ###                 # /  ##     ## ##    ##     ##         ##        
*    /##/           /   ##    ##    ##     ##    ##   e  /###  ##       /##        /   ##     ## ##    /#     ##         ####    / 
*   /  ############/    ### /  ######      ###   ###  n / #### /       /  ########/    ##     ##  ####/ ##    ###         ######/  
*  /     #########       ##/    ####        ###   ### -    ###/       /     #####       ##    ##   ###   ##    ###         #####   
*  #                                                  w               |                       /                                    
*   ##                                                e                \)                    /                                     
*                                                     b                                     /                                      
*                                                                                          /                                       
*
*
* Lion's Share is the very first true follow-me matrix smart contract ever created.
* Now you can build an organization and earn on up to 15 levels.
* https://www.lionsshare.io
* Get your share, join today!
*/

pragma solidity ^0.6.8;

abstract contract LionShareABI {

  function members(address) external virtual returns (uint, uint, bool, address);
}
