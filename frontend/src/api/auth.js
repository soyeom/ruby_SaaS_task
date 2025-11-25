import api from "./client";

export const signup = (payload) => api.post("/signup", payload);

export const login = (payload) => api.post("/login", payload);