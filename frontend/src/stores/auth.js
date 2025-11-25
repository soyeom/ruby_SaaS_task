import { defineStore } from "pinia";
import api from "../api/client";

export const useAuthStore = defineStore("auth", {
    state: () => ({
        user: null,
        loading: false,
        error: null,
    }),
    actions: {
        async signup({ login_id, password, password_conf }) {
            this.loading = true;
            this.error = null;
            try {
                const res = await api.post("/signup", {
                    login_id,
                    password,
                    password_conf,
                });
                this.user = res.data.user;
            } catch (err) {
                this.error = err.response?.data?.message || err.message;
            } finally {
                this.loading = false;
            }
        },

        async login({ login_id, password }) {
            this.loading = true;
            this.error = null;
            try {
                const res = await api.post("/login", {
                    login_id,
                    password,
                });
                this.user = res.data.user;
            } catch (err) {
                this.error = err.response?.data?.message || err.message;
            } finally {
                this.loading = false;
            }
        },

        async logout() {
            this.loading = true;
            this.error = null;
            try {
                await api.post("/logout");
                this.user = null;
            } catch (err) {
                this.error = err.response?.data?.message || err.message;
            } finally {
                this.loading = false;
            }
        },
    },
});