<template>
  <router-link
    :to="to"
    :class="['hover:bg-pink-500 hover:text-white p-2 m-2 rounded']"
    v-slot="{ isActive }"
  >
    <span :class="{ underline: isActive }">
      {{ title }}
    </span>
  </router-link>
</template>

<script setup lang="ts">
defineProps<{
  to: string
  title: string
}>()
</script>
