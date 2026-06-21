import { test, expect } from '@playwright/test';

test('game loads and renders canvas', async ({ page }) => {
  await page.goto('/');
  await page.waitForSelector('canvas', { timeout: 15000 });
  const canvas = page.locator('canvas');
  await expect(canvas).toBeVisible();
});
