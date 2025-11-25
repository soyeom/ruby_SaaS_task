// src/router/index.js
import { createRouter, createWebHistory } from "vue-router";
import LoginView from "../views/LoginView.vue";
import SignupView from "../views/SignupView.vue";
import WorkSpaceListView from "../views/WorkSpaceListView.vue";
import WorkspaceDetailView from "../views/WorkSpaceDetailView.vue";

const routes = [
  { path: "/login", name: "login", component: LoginView },
  { path: "/signup", name: "signup", component: SignupView },
  { path: "/workspaces", name: "workspaces", component: WorkSpaceListView },
  { path: "/workspaces/:id", name: "workspaceDetail", component: WorkspaceDetailView },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
