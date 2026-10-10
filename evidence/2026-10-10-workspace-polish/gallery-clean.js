async page => {
 const root='D:/flutter cuoi ki/evidence/2026-10-10-workspace-polish/';
 const snap=async name=>{const v=page.viewportSize(); await page.mouse.move(5,v.height-5); await page.waitForTimeout(800); await page.screenshot({path:root+name,scale:'css'});};
 const desktopTab=async name=>{await page.getByRole('checkbox',{name,exact:true}).click();};
 const mobileTab=async (current,name)=>{await page.getByRole('button',{name:'Phần đang xem '+current,exact:true}).click(); await page.getByRole('menuitem',{name,exact:true}).click();};
 const edit=async ()=>{await page.getByRole('button',{name:'Thiết kế không gian làm việc Kế hoạch sáng tạo',exact:true}).click(); await page.getByRole('button',{name:'Đổi giao diện',exact:true}).waitFor();};
 await desktopTab('Công việc');
 await page.getByRole('checkbox',{name:'Tất cả trạng thái',exact:true}).click();
 await edit(); await page.getByRole('button',{name:'Đổi giao diện',exact:true}).click(); await page.getByRole('button',{name:'Quay lại',exact:true}).click();
 await desktopTab('Tập trung'); await snap('01-focus-desktop.png');
 await desktopTab('Công việc'); await snap('03-tasks-all-desktop.png');
 await page.getByRole('textbox',{name:'Tìm công việc hoặc tên ghi chú',exact:true}).click(); await page.keyboard.type('kiểm tra'); await snap('02-tasks-filter-desktop.png'); await page.getByRole('button',{name:'Xóa tìm công việc',exact:true}).click();
 await page.setViewportSize({width:390,height:844}); await snap('08-tasks-mobile-light.png');
 await mobileTab('Công việc','Tập trung'); await snap('07-focus-mobile-light.png');
 await mobileTab('Tập trung','Công việc'); await page.setViewportSize({width:1440,height:960});
 await edit(); await page.getByRole('button',{name:'Đổi giao diện',exact:true}).click(); await snap('13-editor-dark.png'); await page.getByRole('button',{name:'Quay lại',exact:true}).click();
 await page.setViewportSize({width:390,height:844}); await snap('09-tasks-mobile-dark.png');
 await mobileTab('Công việc','Tập trung'); await snap('10-focus-mobile-dark.png');
 await page.setViewportSize({width:844,height:390}); await snap('11-focus-landscape-dark.png');
 await page.setViewportSize({width:768,height:1024}); await snap('12-focus-tablet-dark.png');
 await page.setViewportSize({width:1440,height:960});
 return {passed:true,screenshots:10,viewports:['1440x960','390x844','844x390','768x1024'],themes:['light','dark']};
}
