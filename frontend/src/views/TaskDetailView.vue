<template lang="pug">
section.task-page
  .task-shell
    div(v-if="loading") 読み込み中…

    div(v-else-if="!task && errorMessage")
      p.message.error {{ errorMessage }}
      button.btn.btn-gray(@click="goBack") ワークスペースに戻る

    TaskForm(
      v-else
      :title="title"
      :description="description"
      :status="status"
      :category="category"
      :assignee-id="assigneeId"
      :members="members"
      :saving="saving"
      :deleting="deleting"
      :error-message="errorMessage"
      :success-message="successMessage"
      breadcrumb="タスク"
      submit-label="タスクを更新"
      submit-loading-label="更新中…"
      :show-delete="true"
      @update:title="title = $event"
      @update:description="description = $event"
      @update:status="status = $event"
      @update:category="category = $event"
      @update:assigneeId="assigneeId = $event"
      @submit="onUpdate"
      @delete="onDelete"
      @back="goBack"
    )
</template>

<script setup>
import TaskForm from "@/components/TaskLayout.vue";

import { onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import api from "../api/client";

const route = useRoute();
const router = useRouter();

const task = ref(null);

const title = ref("");
const description = ref("");
const status = ref("todo");
const category = ref("");
const assigneeId = ref("");

const members = ref([]);

const loading = ref(false);
const saving = ref(false);
const deleting = ref(false);

const errorMessage = ref("");
const successMessage = ref("");

const workspaceId = () => route.params.workspaceId;
const taskId = () => route.params.taskId;

const fetchMembers = async () => {
  try {
    const res = await api.get(`/workspaces/${workspaceId()}`);
    // show 응답에 { members: [...] } 있다고 가정
    members.value = res.data.members || [];
  } catch (err) {
    console.error("メンバー情報の取得に失敗しました:", err);
  }
};

const fetchTask = async () => {
  loading.value = true;
  errorMessage.value = "";
  successMessage.value = "";

  try {
    const res = await api.get(
      `/workspaces/${workspaceId()}/tasks/${taskId()}`
    );
    // show: { id, title, description, status, category, workspace_id, assignee_id }
    task.value = res.data;
    title.value = res.data.title;
    description.value = res.data.description || "";
    status.value = res.data.status;
    category.value = res.data.category || "";
    assigneeId.value = res.data.assignee_id || "";
  } catch (err) {
    const statusCode = err.response?.status;
    const data = err.response?.data;
    if (statusCode === 401 || statusCode === 403) {
      router.push("/login");
      return;
    }
    if (statusCode === 404) {
      errorMessage.value = "タスクが見つかりませんでした。";
    } else {
      console.error("タスク詳細取得に失敗しました:", err);
      errorMessage.value =
        data?.error || "タスクの取得に失敗しました。";
    }
    task.value = null;
  } finally {
    loading.value = false;
  }
};

const onUpdate = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!title.value.trim()) {
    errorMessage.value = "タスクタイトルは必須です。";
    return;
  }

  try {
    saving.value = true;

    const res = await api.put(
      `/workspaces/${workspaceId()}/tasks/${taskId()}`,
      {
        title: title.value.trim(),
        description: description.value.trim(),
        status: status.value,
        category: category.value.trim(),
        assignee_id: assigneeId.value || null,
      }
    );

    task.value = res.data.task;
    successMessage.value = res.data.message || "タスクを更新しました。";
  } catch (err) {
    const data = err.response?.data;
    console.error("タスク更新に失敗しました:", err);
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value =
        data?.error || "タスクの更新に失敗しました。";
    }
  } finally {
    saving.value = false;
  }
};

const onDelete = async () => {
  const ok = window.confirm(
    "本当にこのタスクを削除しますか？この操作は元に戻せません。"
  );
  if (!ok) return;

  try {
    deleting.value = true;
    await api.delete(`/workspaces/${workspaceId()}/tasks/${taskId()}`);
    router.push(`/workspaces/${workspaceId()}`);
  } catch (err) {
    const data = err.response?.data;
    console.error("タスク削除に失敗しました:", err);
    errorMessage.value = data?.error || "タスクの削除に失敗しました。";
  } finally {
    deleting.value = false;
  }
};

const goBack = () => {
  router.push(`/workspaces/${workspaceId()}`);
};

onMounted(() => {
  fetchTask();
  fetchMembers();
});
</script>