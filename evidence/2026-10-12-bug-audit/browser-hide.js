async page => {
  const problems = [];
  const onError = error => problems.push(String(error));
  const onConsole = message => { if (message.type() === 'error') problems.push(message.text()); };
  page.on('pageerror', onError);
  page.on('console', onConsole);
  const login = await page.request.post('http://127.0.0.1:8058/auth/login', { data: {
    email: 'ui-refresh-owner@example.test', password: 'safe-password-123'
  }});
  const headers = { Authorization: 'Bearer ' + (await login.json()).token };
  const listed = await page.request.get('http://127.0.0.1:8058/notes', { headers });
  const note = (await listed.json()).find(row => row.title === 'Thiết kế NoteTogether');
  if (note.content !== 'Alpha') throw Error('Find unexpectedly wrote note content');
  const accepted = await page.request.post('http://127.0.0.1:8058/notes/' + note.id + '/protection', {
    headers, data: { password: 'note-password-123', confirmation: 'note-password-123' }
  });
  if (accepted.status() !== 200) throw Error('Fixture remote lock failed');
  await page.getByText('0 kết quả', { exact: true }).waitFor({ timeout: 20000 });
  const query = page.getByRole('textbox', { name: 'Tìm trong ghi chú', exact: true });
  const replacement = page.getByRole('textbox', { name: 'Thay bằng', exact: true });
  if (await query.inputValue() !== '' || await replacement.inputValue() !== '') throw Error('Private input retained');
  if (await page.getByRole('button', { name: 'Thay tất cả', exact: true }).isEnabled()) throw Error('Closed source can replace');
  await page.screenshot({ path: 'D:/flutter cuoi ki/output/playwright/bug-audit-find-hidden.png' });
  const after = await page.request.get('http://127.0.0.1:8058/notes', { headers });
  const locked = (await after.json()).find(row => row.id === note.id);
  if (Object.keys(locked).sort().join(',') !== 'id,locked,pinned_at,revision,role,shared') throw Error('Private listing metadata retained');
  if (problems.length) throw Error(JSON.stringify(problems));
  page.removeListener('pageerror', onError);
  page.removeListener('console', onConsole);
  return { result: 'PASS', remoteLockClearsFindInput: true, replacementDisabled: true,
    listingFields: Object.keys(locked).sort(), findDidNotWriteContent: true, pageConsoleErrors: problems.length, tokensRecorded: false };
}
