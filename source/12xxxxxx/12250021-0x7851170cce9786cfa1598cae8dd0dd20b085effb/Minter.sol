// SPDX-License-Identifier: UNLICENSED
// This code is the property of the Aardbanq DAO.
// The Aardbanq DAO is located at 0x829c094f5034099E91AB1d553828F8A765a3DaA1 on the Ethereum Main Net.
// It is the author's wish that this code should be open sourced under the MIT license, but the final 
// decision on this would be taken by the Aardbanq DAO with a vote once sufficient ABQ tokens have been 
// distributed.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
pragma solidity >=0.7.0;

interface Minter
{
    function mint(address _target, uint256 _amount) external;
}
