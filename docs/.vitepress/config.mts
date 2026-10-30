import { defineConfig } from 'vitepress'

const base = '/EdgeBench/'

export default defineConfig({
  title: 'SForge',
  description: 'Evaluation harness for long-horizon agent tasks',
  base,

  locales: {
    en: {
      label: 'English',
      lang: 'en',
      link: '/en/',
      themeConfig: {
        logoLink: `${base}en/guide/introduction`,
        nav: [
          { text: 'Guide', link: '/en/guide/introduction' },
          { text: 'Examples', link: '/en/examples/single-task-docker' },
          { text: 'Configuration', link: '/en/configuration/environment-variables' },
          { text: 'Features', link: '/en/features/iterative-evaluation' },
          { text: 'Developer', link: '/en/tasks/task-format' },
          { text: 'Reference', link: '/en/reference/cli' },
        ],
        sidebar: {
          '/en/': [
            {
              text: 'Guide',
              items: [
                { text: 'Introduction', link: '/en/guide/introduction' },
                { text: 'Getting Started', link: '/en/guide/getting-started' },
                { text: 'Supported Agents', link: '/en/guide/agents' },
              ],
            },
            {
              text: 'Examples',
              items: [
                { text: 'Single Task (Docker)', link: '/en/examples/single-task-docker' },
                { text: 'Single Task (E2B)', link: '/en/examples/single-task-e2b' },
                { text: 'All Tasks (Kubernetes)', link: '/en/examples/all-tasks-k8s' },
              ],
            },
            {
              text: 'Configuration',
              items: [
                { text: 'Environment Variables', link: '/en/configuration/environment-variables' },
                { text: 'Experiment Configuration', link: '/en/configuration/experiments' },
                { text: 'Container Backends', link: '/en/configuration/container-backends' },
                { text: 'Network Setup', link: '/en/configuration/network-setup' },
              ],
            },
            {
              text: 'Features',
              items: [
                { text: 'Iterative Evaluation Framework', link: '/en/features/iterative-evaluation' },
                { text: 'Network Isolation', link: '/en/features/network-isolation' },
                { text: 'Game Mode', link: '/en/features/game-mode' },
                { text: 'Viewer and Replay', link: '/en/features/viewer' },
              ],
            },
            {
              text: 'Developer',
              items: [
                { text: 'Task Format', link: '/en/tasks/task-format' },
                { text: 'Pre-built Images', link: '/en/features/prebuilt-images' },
                { text: 'Judge HTTP API', link: '/en/reference/judge-api' },
              ],
            },
            {
              text: 'Reference',
              items: [
                { text: 'CLI Commands', link: '/en/reference/cli' },
                { text: 'Troubleshooting', link: '/en/reference/troubleshooting' },
              ],
            },
          ],
        },
      },
    },
    zh: {
      label: '中文',
      lang: 'zh-CN',
      link: '/zh/',
      themeConfig: {
        logoLink: `${base}zh/guide/introduction`,
        nav: [
          { text: '指南', link: '/zh/guide/introduction' },
          { text: '示例', link: '/zh/examples/single-task-docker' },
          { text: '配置', link: '/zh/configuration/environment-variables' },
          { text: '功能', link: '/zh/features/iterative-evaluation' },
          { text: '开发者', link: '/zh/tasks/task-format' },
          { text: '参考', link: '/zh/reference/cli' },
        ],
        sidebar: {
          '/zh/': [
            {
              text: '指南',
              items: [
                { text: '简介', link: '/zh/guide/introduction' },
                { text: '快速开始', link: '/zh/guide/getting-started' },
                { text: '支持的 Agent', link: '/zh/guide/agents' },
              ],
            },
            {
              text: '示例',
              items: [
                { text: '单任务运行 (Docker)', link: '/zh/examples/single-task-docker' },
                { text: '单任务运行 (E2B)', link: '/zh/examples/single-task-e2b' },
                { text: '全部任务 (Kubernetes)', link: '/zh/examples/all-tasks-k8s' },
              ],
            },
            {
              text: '配置',
              items: [
                { text: '环境变量', link: '/zh/configuration/environment-variables' },
                { text: '实验配置', link: '/zh/configuration/experiments' },
                { text: '容器后端', link: '/zh/configuration/container-backends' },
                { text: '网络配置', link: '/zh/configuration/network-setup' },
              ],
            },
            {
              text: '功能',
              items: [
                { text: '迭代评测框架', link: '/zh/features/iterative-evaluation' },
                { text: '网络隔离', link: '/zh/features/network-isolation' },
                { text: '游戏模式', link: '/zh/features/game-mode' },
                { text: '结果查看与回放', link: '/zh/features/viewer' },
              ],
            },
            {
              text: '开发者',
              items: [
                { text: '任务格式', link: '/zh/tasks/task-format' },
                { text: '预构建镜像', link: '/zh/features/prebuilt-images' },
                { text: 'Judge HTTP API', link: '/zh/reference/judge-api' },
              ],
            },
            {
              text: '参考',
              items: [
                { text: 'CLI 命令参考', link: '/zh/reference/cli' },
                { text: '故障排除', link: '/zh/reference/troubleshooting' },
              ],
            },
          ],
        },
      },
    },
  },

  themeConfig: {
    search: {
      provider: 'local',
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/ByteDance-Seed/EdgeBench' },
    ],
  },
})
