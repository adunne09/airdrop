import { ethers } from 'ethers'
import { defineStore } from 'pinia'

interface RootState {
  address: string
  contract: ethers.Contract
  items: any[]
}

export const useStore = defineStore('main', {
  // other options...
})

// stash wip commits instead?

// no any
