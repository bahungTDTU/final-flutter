async page => {
  const [download] = await Promise.all([
    page.waitForEvent('download'),
    page.getByRole('button', {name: 'Xuất file', exact: true}).click()
  ]);
  await download.saveAs('C:/Users/LENOVO/.codex/visualizations/2026/10/01/01a0f5e8-00e9-7261-9755-6f8d56861ace/workspace-features-2026-10-10/exported.notetogether.json');
  console.log('Actual download saved: ' + download.suggestedFilename());
}
