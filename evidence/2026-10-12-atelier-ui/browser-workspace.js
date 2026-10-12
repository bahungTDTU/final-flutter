async page => {
  const sections=[['Tổng quan','workspace'],['Yêu thích','favorites'],['Gần đây','recent'],
    ['Bộ sưu tập','collections'],['Công việc','tasks'],['Mẫu riêng','personal-templates'],
    ['Nhập / xuất','transfer'],['Tập trung','focus'],['Kế hoạch','planner']];
  for (const [label,file] of sections) {
    await page.getByRole('checkbox',{name:label,exact:true}).click();
    await page.mouse.move(0,0);
    await page.waitForTimeout(300);
    await page.screenshot({path:`output/playwright/atelier-ui/${file}-desktop-dark.png`});
    if(file==='focus'||file==='planner') {
      await page.setViewportSize({width:390,height:844});
      await page.waitForTimeout(300);
      await page.screenshot({path:`output/playwright/atelier-ui/${file}-phone-dark.png`});
      await page.setViewportSize({width:1440,height:1000});
    }
  }
  return {sections:9,phoneSections:2,appErrors:page.atelier.errors,consoleErrors:page.atelier.consoleErrors};
}
