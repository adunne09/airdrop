<template>
  <button
    type="button"
    :class="[
      'w-full font-bold rounded px-2 py-1',
      {
        'border-2 bg-pink-500 text-white cursor-pointer hover:bg-white  border-pink-500 hover:text-pink-500':
          kind === 'primary' && !disabled,
      },
      {
        'border-2 text-pink-500 hover:bg-pink-500  border-pink-500 hover:text-white':
          kind === 'secondary' && !disabled,
      },
      {
        'text-pink-500 underline': kind === 'text' && !disabled,
      },
      { 'border-2 text-gray-400 cursor-not-allowed': disabled },
    ]"
  >
    <slot />
  </button>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    kind?: 'primary' | 'seconday' | 'text'
    disabled?: boolean
    loading?: boolean
  }>(),
  {
    kind: 'primary',
  }
)
</script>

<style scoped></style>
