async page => {
 const root='D:/flutter cuoi ki/evidence/2026-10-10-planner-motion/';
 const shot=async name=>{const v=page.viewportSize();await page.mouse.move(5,v.height-5);await page.waitForTimeout(650);await page.screenshot({path:root+name,scale:'css'});};
 await page.getByRole('button',{name:'Chặng đang xem Dự kiến (1)',exact:true}).click();
 await page.getByRole('menuitem',{name:'Đang làm (1)',exact:true}).click();
 await page.mouse.move(190,700); await page.mouse.wheel(0,250); await shot('06-planner-mobile-card-light.png');
 await page.mouse.wheel(0,-2000); await page.setViewportSize({width:1440,height:1080});
 await page.getByRole('group',{name:/^Kế hoạch sáng tạo[\s\S]*Ưu tiên cao/}).click();
 await page.getByRole('button',{name:'Đổi giao diện',exact:true}).click();
 await page.getByRole('button',{name:'Quay lại',exact:true}).click();
 await shot('07-kanban-desktop-dark.png');
 await page.setViewportSize({width:390,height:844}); await shot('08-planner-mobile-top-dark.png');
 await page.mouse.move(190,700); await page.mouse.wheel(0,250); await shot('09-planner-mobile-card-dark.png');
 await page.mouse.wheel(0,-2000); await page.setViewportSize({width:768,height:1024}); await shot('10-planner-tablet-dark.png');
 await page.setViewportSize({width:844,height:390});
 await page.mouse.move(420,330); await page.mouse.wheel(0,550); await shot('11-planner-landscape-dark.png');
 await page.mouse.wheel(0,-2000); await page.setViewportSize({width:1440,height:1080});
 await page.getByRole('button',{name:'Thao tác kế hoạch Thông tin cần bảo vệ',exact:true}).click();
 await page.getByRole('menuitem',{name:'Ưu tiên và ngày hạn',exact:true}).click();
 await page.getByRole('button',{name:'Chọn ngày hạn',exact:true}).click();
 await shot('12-calendar-dark.png');
 return {passed:true,viewports:['1440x1080','390x844','768x1024','844x390'],themes:['light','dark'],mobileStageChange:true,calendarOpened:true};
}
