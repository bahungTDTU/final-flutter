async page => {
  await page.setViewportSize({width:1440,height:960});
  await page.reload();
  await page.locator('flt-semantics-placeholder').evaluate(el => el.click());
  await page.getByRole('button', {name: 'Không gian làm việc', exact: true}).first().click();
  await page.getByRole('checkbox', {name: 'Yêu thích', exact: true}).click();
  await page.getByRole('button', {name: 'Kế hoạch sáng tạo Ghi chú của bạn', exact: true}).click();
  await page.getByRole('button', {name: 'Đổi giao diện', exact: true}).click();
  await page.getByRole('button', {name: 'Quay lại', exact: true}).click();
  await page.getByRole('checkbox', {name: 'Tổng quan', exact: true}).click();
  await page.waitForTimeout(700); // Settle Flutter route/theme transition before evidence capture.
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/11-overview-final-desktop.png'});
  await page.getByRole('checkbox', {name: 'Công việc', exact: true}).click();
  await page.getByRole('checkbox', {name: 'Hoàn thành', exact: true}).click();
  await page.waitForTimeout(700); // Settle Flutter route/theme transition before evidence capture.
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/12-tasks-final-desktop.png'});
  await page.getByRole('checkbox', {name: 'Yêu thích', exact: true}).click();
  await page.waitForTimeout(700); // Settle Flutter route/theme transition before evidence capture.
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/13-favorites-after-lock.png'});
  await page.getByRole('button', {name: 'Kế hoạch sáng tạo Ghi chú của bạn', exact: true}).click();
  await page.getByRole('button', {name: 'Đổi giao diện', exact: true}).click();
  await page.getByRole('button', {name: 'Quay lại', exact: true}).click();
  await page.getByRole('checkbox', {name: 'Tổng quan', exact: true}).click();
  await page.waitForTimeout(700); // Settle Flutter route/theme transition before evidence capture.
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/14-overview-final-dark.png'});
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(700); // Settle Flutter route/theme transition before evidence capture.
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/15-overview-mobile-dark.png'});
  await page.getByRole('checkbox', {name: 'Công việc', exact: true}).click();
  await page.waitForTimeout(700); // Settle Flutter route/theme transition before evidence capture.
  await page.screenshot({path:'output/playwright/workspace-2026-10-10/16-tasks-mobile-dark.png'});
}
