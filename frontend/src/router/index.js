// src/router/index.js
import { createRouter, createWebHistory } from "vue-router";
import LoginView from "../views/LoginView.vue";
import SignupView from "../views/SignupView.vue";
import WorkspaceListView from "../views/WorkspaceListView.vue";
import  WorkspaceDetailView from "../views/WorkspaceDetailView.vue";
import TaskDetailView from "../views/TaskDetailView.vue";
import TaskCreateView from "../views/TaskCreateView.vue";

const routes = [
  { path: "/login", name: "login", component: LoginView },
  { path: "/signup", name: "signup", component: SignupView },
  { path: "/workspaces", name: "workspaces", component: WorkspaceListView },
  { path: "/workspaces/:id", name: "workspaceDetail", component: WorkspaceDetailView },
  { path: "/workspaces/:workspaceId/tasks/:taskId", name: "taskDetail", component: TaskDetailView },
  { path: "/workspaces/:workspaceId/tasks/create", name: "taskCreate", component: TaskCreateView },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
