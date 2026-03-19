import { createContext, ReactNode, useCallback, useContext, useEffect, useMemo, useState } from "react";

import { apiRequest } from "../lib/api";
import { clearStoredToken, getStoredToken, setStoredToken } from "../lib/auth";
import { AuthUser, TokenResponse } from "../types";

type RegisterPayload = {
  first_name: string;
  last_name: string;
  email: string;
  password: string;
};

type LoginPayload = {
  email: string;
  password: string;
};

type AuthContextValue = {
  user: AuthUser | null;
  token: string | null;
  isLoading: boolean;
  register: (payload: RegisterPayload) => Promise<void>;
  login: (payload: LoginPayload) => Promise<AuthUser>;
  logout: () => void;
  refreshUser: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(getStoredToken());
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const refreshUser = useCallback(async () => {
    const currentToken = getStoredToken();
    if (!currentToken) {
      setUser(null);
      setToken(null);
      setIsLoading(false);
      return;
    }

    try {
      const me = await apiRequest<AuthUser>("/auth/me", { token: currentToken });
      setUser(me);
      setToken(currentToken);
    } catch {
      clearStoredToken();
      setUser(null);
      setToken(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void refreshUser();
  }, [refreshUser]);

  const register = useCallback(async (payload: RegisterPayload) => {
    await apiRequest<AuthUser>("/auth/register", {
      method: "POST",
      body: payload
    });
  }, []);

  const login = useCallback(async (payload: LoginPayload) => {
    const response = await apiRequest<TokenResponse>("/auth/login", {
      method: "POST",
      body: payload
    });

    setStoredToken(response.access_token);
    setToken(response.access_token);

    const me = await apiRequest<AuthUser>("/auth/me", {
      token: response.access_token
    });
    setUser(me);
    return me;
  }, []);

  const logout = useCallback(() => {
    clearStoredToken();
    setToken(null);
    setUser(null);
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      token,
      isLoading,
      register,
      login,
      logout,
      refreshUser
    }),
    [user, token, isLoading, register, login, logout, refreshUser]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used inside AuthProvider");
  }
  return context;
}
