<template>
  <header class="w-full flex justify-center my-8">
    <div>
      <router-link to="/" class="text-4xl font-bold hover:text-pink-500">
        Airdrop Bazaar
      </router-link>
      <div class="flex mt-4 items-center border-2 border-pink-500 rounded-lg">
        <HeaderLink to="/create-item" title="Create Item" />
        <div class="border-x-2 border-pink-500">
          <HeaderLink to="/unclaimed-items" title="View Unclaimed Items" />
        </div>
        <HeaderLink to="/created-items" title="View Created Items" />
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import HeaderLink from '@/components/HeaderLink.vue'
</script>

<style scoped></style>
