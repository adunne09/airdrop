<template>
  <header class="w-full flex justify-center my-8">
    <div class="flex-1 mb-7 border-b-2 border-pink-500" />
    <div class="flex-1">
      <router-link to="/" class="text-4xl font-bold hover:text-pink-500">
        Airdrop Bazaar
      </router-link>
      <div
        class="flex justify-around mt-4 items-center border-2 border-pink-500 rounded-lg"
      >
        <HeaderLink to="/create-item" title="Create Item" />
        <div class="border-x-2 border-pink-500 px-4">
          <HeaderLink to="/unclaimed-items" title="Unclaimed Items" />
        </div>
        <HeaderLink to="/created-items" title="Created Items" />
      </div>
    </div>
    <div class="flex-1 mb-7 border-b-2 border-pink-500" />
  </header>
</template>

<script setup lang="ts">
import HeaderLink from '@/components/HeaderLink.vue'
</script>

<style scoped></style>
