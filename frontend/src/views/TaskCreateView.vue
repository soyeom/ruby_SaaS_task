<template lang="pug">
section.task-page
  .task-shell
    TaskForm(
      :title="title"
      :description="description"
      :status="status"
      :category="category"
      :assignee-id="assigneeId"
      :members="members"
      :saving="saving"
      :deleting="false"
      :error-message="errorMessage"
      :success-message="successMessage"
      breadcrumb="タスク / 新規作成"
      submit-label="タスクを作成"
      submit-loading-label="作成中…"
      :show-delete="false"
      @update:title="title = $event"
      @update:description="description = $event"
      @update:status="status = $event"
      @update:category="category = $event"
      @update:assigneeId="assigneeId = $event"
      @submit="onCreate"
      @back="goBack"
    )
</template>

<script setup>
import TaskForm from "@/components/TaskLayout.vue";

import { ref, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import api from "../api/client";

const route = useRoute();
const router = useRouter();

const title = ref("");
const description = ref("");
const status = ref("todo");
const category = ref("");
const assigneeId = ref("");

const members = ref([]);

const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const workspaceId = () => route.params.workspaceId;

const fetchMembers = async () => {
  try {
    const res = await api.get(`/workspaces/${workspaceId()}`);
    members.value = res.data.members || [];
  } catch (err) {
    console.error("メンバー情報の取得に失敗しました:", err);
  }
};

const onCreate = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!title.value.trim()) {
    errorMessage.value = "タスクタイトルは必須です。";
    return;
  }

  try {
    saving.value = true;

    const res = await api.post(`/workspaces/${workspaceId()}/tasks`, {
      title: title.value.trim(),
      description: description.value.trim(),
      status: status.value,
      category: category.value.trim(),
      assignee_id: assigneeId.value || null,
    });

    successMessage.value = res.data.message || "タスクを作成しました。";

    router.push(`/workspaces/${workspaceId()}`);
  } catch (err) {
    const data = err.response?.data;
    console.error("タスク作成に失敗しました:", err);
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value =
        data?.error || "タスクの作成に失敗しました。";
    }
  } finally {
    saving.value = false;
  }
};

const goBack = () => {
  router.push(`/workspaces/${workspaceId()}`);
};

onMounted(() => {
  fetchMembers();
});
</script>