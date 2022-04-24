<template>
  <label :for="id" class="flex items-center gap-x-2 cursor-pointer">
    <input
      :id="id"
      type="checkbox"
      :checked="checked"
      :disabled="disabled"
      v-bind="$attrs"
      class="sr-only"
    />

    <span
      :class="{ 'shadow-md border border-pink-500 rounded': !disabled }"
      aria-hidden="true"
    >
      <svg
        width="14"
        height="14"
        viewBox="0 0 14 14"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
      >
        <rect width="14" height="14" rx="1" />
        <path
          d="M4 7.5L6.25 9.5L10 4.5"
          stroke="#EC4899"
          stroke-width="2"
          v-if="checked"
        />
      </svg>
    </span>

    <span
      class="text-base leading-3 tracking-wide font-bold"
      :class="[disabled ? 'text-gray-300' : 'text-pink-500']"
    >
      <slot />
    </span>
  </label>
</template>

<script setup lang="ts">
import { v4 } from 'uuid'

defineProps<{
  disabled?: boolean
  checked: boolean
}>()

const id = v4()
</script>

<style scoped></style>
