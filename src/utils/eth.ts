import { ethers } from 'ethers'
import detectEthereumProvider from '@metamask/detect-provider'

import Airdrop from '../../out/Airdrop.sol/Airdrop.json'

const AIRDROP_CONTRACT_ADDRESS = import.meta.env
  .VITE_APP_AIRDROP_CONTRACT_ADDRESS
const CHAIN_ID = +import.meta.env.VITE_APP_POLYGON_MUMBAI_TESTNET_CHAIN_ID // parse to int

export const establishConnectionAndGetAirdropContract = async (): Promise<
  { address: string; contract: ethers.Contract } | { message: unknown }
> => {
  try {
    // establish initial eth connection
    const connection = (await detectEthereumProvider()) as any
    if (!connection || connection !== window.ethereum) {
      throw new Error('Please install Metamask')
    }

    const ethereum = window.ethereum as any

    // trigger the metamask popup if the user needs to authorize connection
    const [address] = await ethereum.request({
      method: 'eth_requestAccounts',
    })
    if (!address) {
      throw new Error('Please authorize an account to connect with')
    }

    // assert that the user is on the correct chain id
    const chainIdHex = await ethereum.request({ method: 'eth_chainId' })
    const chainId = ethers.BigNumber.from(chainIdHex).toNumber()
    if (chainId !== CHAIN_ID) {
      throw new Error(
        `Please configure your metamast to use the ${CHAIN_ID} chain id`
      )
    }

    const provider = new ethers.providers.Web3Provider(connection)

    const signer = provider.getSigner(address)

    return {
      address,
      contract: new ethers.Contract(
        AIRDROP_CONTRACT_ADDRESS,
        Airdrop.abi,
        signer
      ),
    }
  } catch (e) {
    return { message: e }
  }
}

export const registerAccountChangeHandler = (
  handler: (accounts: string[]) => void
): void => {
  const ethereum = window.ethereum as any
  ethereum.on('accountsChanged', (accounts: string[]) => handler(accounts))
}
