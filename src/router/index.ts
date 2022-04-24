import { RouteRecordRaw, createRouter, createWebHistory } from 'vue-router'

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    name: 'home',
    component: () => import('../views/Home.vue'),
    meta: {
      title: 'Home',
    },
  },
  {
    path: '/create-item',
    name: 'create-item',
    component: () => import('../views/create-item/CreateItem.vue'),

    meta: {
      title: 'Create Item',
    },
  },
  {
    path: '/unclaimed-items',
    name: 'unclaimed-items',
    component: () => import('../views/UnclaimedItems.vue'),
    meta: {
      title: 'Unclaimed Items',
    },
  },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  },
})

router.afterEach((to) => {
  function generatePageTitle(pageTitle?: string): string {
    const title = ['Airdrop']
    if (pageTitle) title.push(pageTitle)
    return title.join(' | ')
  }

  document.title = generatePageTitle(to.meta.title as string | undefined)
})

export default router
