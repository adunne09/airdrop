<template>
  <div aria-label="progress bar" role="presentation">
    {{ text }}
    <div class="flex items-center justify-between">
      <div ref="progressBar" class="w-full">
        <span
          aria-label="progress indicator"
          role="presentation"
          v-for="i in state.barCount"
          :class="[
            'progress-indicator inline-block last:mr-0 border border-pink-500 rounded-sm',
            { 'bg-pink-500': barIsComplete(i) },
          ]"
          :key="`indicator-${i}`"
        />
      </div>
      <div class="flex-shrink-0">
        <slot />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, Ref } from '@vue/reactivity'
import { onMounted, onUnmounted, watch } from '@vue/runtime-core'

const props = withDefaults(
  defineProps<{
    percentage?: number | string
    loading?: boolean
    text?: string
  }>(),
  {
    percentage: 0,
    loading: false,
  }
)

interface State {
  interval?: NodeJS.Timer
  barCount: number
  currentCount: number
}

const state: Ref<State> = ref({
  barCount: 0,
  currentCount: 0,
})

const BAR_WIDTH = 7
const progressBar: Ref<HTMLDivElement | null> = ref(null)

const calcBarCount = () => {
  const maxWidth = progressBar.value?.offsetWidth ?? 0
  if (maxWidth > 0) {
    state.value.barCount = Math.round(maxWidth / BAR_WIDTH) - 1
  }
}

const barIsComplete = (i: number): boolean => {
  if (props.loading) {
    return i <= state.value.currentCount
  }

  const percentage = Number(props.percentage) / 100
  return state.value.barCount * percentage >= i
}

onMounted(() => {
  calcBarCount()

  if (props.loading) {
    state.value.interval = setInterval(() => {
      if (state.value.currentCount === state.value.barCount) {
        state.value.currentCount = 0
        return
      }

      state.value.currentCount++
    }, 10)
  }
})

onUnmounted(() => {
  clearInterval(state.value.interval!)
})

watch(
  () => props.loading,
  () => {
    if (!props.loading) {
      clearInterval(state.value.interval!)
    }
  }
)
</script>

<style scoped>
.progress-indicator {
  height: 10px;
  width: 5px;
  margin-right: 2px;
  transform: skew(-25deg);
}
</style>
