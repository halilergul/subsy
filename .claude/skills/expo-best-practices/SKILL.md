---
name: expo-best-practices
description: Expo + React Native best practices with NativeWind, Supabase, and Expo Router. Focus on performance, list rendering, animations, navigation, and mobile-specific patterns. Triggers on building screens, optimizing lists, implementing navigation flows, or working with native modules.
---

# Expo + React Native Best Practices

## Routing — Expo Router

File-based, similar to Next.js App Router.

```
app/
  _layout.tsx               # Root
  (auth)/
    _layout.tsx             # Auth group (Stack)
    login.tsx               # /login
    signup.tsx              # /signup
  (tabs)/
    _layout.tsx             # Tabs
    index.tsx               # /
    profile.tsx             # /profile
  posts/
    [id].tsx                # /posts/:id
  +not-found.tsx
```

```tsx
// app/_layout.tsx
import { Stack } from 'expo-router';

export default function RootLayout() {
  return <Stack screenOptions={{ headerShown: false }} />;
}
```

Programmatic navigation:
```ts
import { router } from 'expo-router';
router.push('/profile');
router.replace('/login');
router.back();
```

## Supabase Client (with AsyncStorage)

```ts
// lib/supabase/client.ts
import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
  {
    auth: {
      storage: AsyncStorage,
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
    },
  }
);
```

Auth state hook:
```ts
// hooks/useAuth.ts
import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase/client';
import type { Session } from '@supabase/supabase-js';

export function useAuth() {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => sub.subscription.unsubscribe();
  }, []);

  return { session, loading };
}
```

## Lists — FlashList for Anything Over 50 Items

```tsx
import { FlashList } from '@shopify/flash-list';

<FlashList
  data={posts}
  renderItem={({ item }) => <PostCard post={item} />}
  estimatedItemSize={120}
  keyExtractor={(item) => item.id}
  onEndReached={loadMore}
  onEndReachedThreshold={0.5}
  refreshing={refreshing}
  onRefresh={refresh}
/>
```

Anti-patterns:
- ❌ FlatList with 500+ items
- ❌ ScrollView with many children (no virtualization)
- ❌ `key={index}` instead of stable IDs

## Images — expo-image (not RN's Image)

```tsx
import { Image } from 'expo-image';

<Image
  source={{ uri: post.imageUrl }}
  contentFit="cover"
  transition={200}
  cachePolicy="memory-disk"
  style={{ width: '100%', height: 200 }}
/>
```

Why: better caching, blurhash placeholders, faster decoding.

## Styling — NativeWind

```tsx
<View className="flex-1 bg-white dark:bg-gray-900">
  <Text className="text-2xl font-bold text-gray-900 dark:text-white">
    Hello
  </Text>
  <Pressable className="mt-4 rounded-lg bg-blue-600 px-4 py-3 active:opacity-80">
    <Text className="text-center font-semibold text-white">Press me</Text>
  </Pressable>
</View>
```

Dark mode via `useColorScheme()`:
```ts
import { useColorScheme } from 'nativewind';
const { colorScheme, toggleColorScheme } = useColorScheme();
```

## Animations — Reanimated (UI thread)

```tsx
import Animated, { useSharedValue, useAnimatedStyle, withTiming } from 'react-native-reanimated';

const opacity = useSharedValue(0);
const animatedStyle = useAnimatedStyle(() => ({
  opacity: opacity.value,
}));

useEffect(() => {
  opacity.value = withTiming(1, { duration: 300 });
}, []);

return <Animated.View style={animatedStyle}>...</Animated.View>;
```

Avoid:
- ❌ `Animated` API from `react-native` (JS thread, janky)
- ❌ Animating `width`, `height`, `top`, `left` (use transforms instead)

## Forms

```tsx
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { loginSchema } from '@/lib/validations/auth';
import { TextInput, Pressable, Text, View } from 'react-native';

export function LoginForm() {
  const { control, handleSubmit, formState: { errors } } = useForm({
    resolver: zodResolver(loginSchema),
  });

  return (
    <View>
      <Controller
        control={control}
        name="email"
        render={({ field: { onChange, onBlur, value } }) => (
          <TextInput
            className="rounded border border-gray-300 px-3 py-2"
            placeholder="Email"
            onChangeText={onChange}
            onBlur={onBlur}
            value={value}
            keyboardType="email-address"
            autoCapitalize="none"
          />
        )}
      />
      {errors.email && <Text className="text-red-600">{errors.email.message}</Text>}
      <Pressable onPress={handleSubmit(onSubmit)} className="mt-4 bg-blue-600 py-3 rounded">
        <Text className="text-white text-center">Login</Text>
      </Pressable>
    </View>
  );
}
```

## Environment Variables

`.env`:
```
EXPO_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

Rule: only `EXPO_PUBLIC_*` is bundled. Server-only secrets stay in Edge Functions.

## EAS Build & Update

`eas.json` configures build profiles. Common commands:
```bash
eas build:configure
eas build --platform ios --profile preview
eas update --branch production --message "Fix login bug"
```

OTA updates: works for JS-only changes. Native module changes require a new build.

## Common Anti-Patterns

- ❌ FlatList for huge lists → use FlashList
- ❌ `Image` from React Native → use `expo-image`
- ❌ `Animated` API → use Reanimated
- ❌ `setInterval` in screen without cleanup → memory leak
- ❌ Service role key in mobile bundle → security disaster (anon key only)
- ❌ Skipping RLS in DB → mobile clients bypass server-side checks
- ❌ Heavy work on JS thread blocking UI → offload to InteractionManager or background
- ❌ Re-rendering whole list on parent state change → memoize item components
