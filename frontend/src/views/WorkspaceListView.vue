<template lang="pug">
section.workspace-page
  .workspace-shell
    .workspace-header
      h1.page-title ワークスペース
      p.page-subtitle
        | ログイン中のユーザーが所属しているワークスペースの一覧です。

    //- 생성 폼
    .workspace-create-card
      h2.card-title ワークスペースを作成
      form(@submit.prevent="onCreate")
        .form-row
          input.name-input(
            type="text"
            v-model="newName"
            placeholder="新しいワークスペース名"
          )
          button.create-button(type="submit" :disabled="creating")
            span(v-if="creating") 作成中…
            span(v-else) 作成する
        p.form-error(v-if="errorMessage") {{ errorMessage }}
        p.form-success(v-if="successMessage") {{ successMessage }}

    //- 리스트 영역
    .workspace-list-card
      h2.card-title ワークスペース一覧

      div(v-if="loading") 読み込み中…

      ul.workspace-list(v-else)
        li.workspace-item(
          v-for="ws in workspaces"
          :key="ws.id"
          @click="goToWorkspace(ws.id)"
        )
          .ws-name {{ ws.name }}
          .ws-id text ID: {{ ws.id }}

      p.empty-text(v-if="!loading && workspaces.length === 0")
        | 所属しているワークスペースがありません。
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import api from "../api/client";

const router = useRouter();

const workspaces = ref([]);
const loading = ref(false);

const newName = ref("");
const creating = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const fetchWorkspaces = async () => {
  loading.value = true;
  try {
    const res = await api.get("/workspaces");
    // index: workspaces.as_json(only: [:id, :name])
    workspaces.value = res.data;
  } catch (err) {
    const status = err.response?.status;
    if (status === 401 || status === 403) {
      router.push("/login");
    } else {
      console.error("ワークスペース一覧取得に失敗しました:", err);
      errorMessage.value = "ワークスペース一覧の取得に失敗しました。";
    }
  } finally {
    loading.value = false;
  }
};

const onCreate = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!newName.value.trim()) {
    errorMessage.value = "ワークスペース名は必須です。";
    return;
  }

  try {
    creating.value = true;
    const res = await api.post("/workspaces", {
      name: newName.value.trim(), // 컨트롤러에서 params[:name] 사용
    });

    // 성공 응답:
    // {
    //   message: "ワークスペースを作成しました。",
    //   workspace: { id: ..., name: ... }
    // }
    successMessage.value = res.data.message || "ワークスペースを作成しました。";

    // 새로 생성된 워크스페이스를 리스트에 추가
    workspaces.value.push(res.data.workspace);
    newName.value = "";
  } catch (err) {
    const data = err.response?.data;
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value =
        data?.error || "ワークスペースの作成に失敗しました。";
    }
  } finally {
    creating.value = false;
  }
};

const goToWorkspace = (id) => {
  router.push(`/workspaces/${id}`);
};

onMounted(() => {
  fetchWorkspaces();
});
</script>

<style scoped>
.workspace-page {
  min-height: 100vh;
  background: #f7f7f5;
  display: flex;
  justify-content: center;
  padding: 32px 16px;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
    sans-serif;
}

.workspace-shell {
  width: 100%;
  max-width: 800px;
}

.workspace-header {
  margin-bottom: 20px;
}

.page-title {
  font-size: 22px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 4px;
}

.page-subtitle {
  font-size: 13px;
  color: #6b7280;
}

.workspace-create-card,
.workspace-list-card {
  background: #ffffff;
  border-radius: 12px;
  padding: 20px 18px;
  border: 1px solid rgba(15, 23, 42, 0.08);
  box-shadow: 0 10px 30px rgba(15, 23, 42, 0.04);
  margin-bottom: 16px;
}

.card-title {
  font-size: 15px;
  font-weight: 600;
  color: #111827;
  margin-bottom: 12px;
}

.form-row {
  display: flex;
  gap: 8px;
}

.name-input {
  flex: 1;
  padding: 8px 10px;
  border-radius: 10px;
  border: 1px solid #d1d5db;
  font-size: 14px;
  background-color: #f9fafb;
  outline: none;
  transition: border-color 0.15s ease, box-shadow 0.15s ease,
    background-color 0.15s ease;
}

.name-input:focus {
  border-color: #6366f1;
  background-color: #ffffff;
  box-shadow: 0 0 0 1px rgba(99, 102, 241, 0.4);
}

.create-button {
  border: none;
  border-radius: 999px;
  padding: 8px 14px;
  font-size: 14px;
  font-weight: 500;
  background: #111827;
  color: #ffffff;
  cursor: pointer;
  white-space: nowrap;
}

.create-button:disabled {
  opacity: 0.6;
  cursor: default;
}

.form-error {
  margin-top: 8px;
  font-size: 12px;
  color: #b91c1c;
}

.form-success {
  margin-top: 8px;
  font-size: 12px;
  color: #15803d;
}

.workspace-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.workspace-item {
  padding: 10px 10px;
  border-radius: 10px;
  border: 1px solid #e5e7eb;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  font-size: 14px;
}

.workspace-item + .workspace-item {
  margin-top: 8px;
}

.workspace-item:hover {
  background: #f9fafb;
}

.ws-name {
  font-weight: 500;
  color: #111827;
}

.ws-id {
  font-size: 12px;
  color: #9ca3af;
}

.empty-text {
  font-size: 13px;
  color: #6b7280;
  margin-top: 4px;
}
</style>
