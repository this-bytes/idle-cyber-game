async function getJson(url) {
  const res = await fetch(url, { cache: 'no-cache' })
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}

async function putJson(url, data) {
  const res = await fetch(url, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data, null, 2)
  })
  if (!res.ok) throw new Error(await res.text())
  return res.json()
}

document.getElementById('loadDefs').addEventListener('click', async () => {
  const area = document.getElementById('defsArea')
  const status = document.getElementById('defsStatus')
  try {
    const data = await getJson('/admin/data/defs')
    area.value = JSON.stringify(data, null, 2)
    status.textContent = 'Loaded defs.json'
  } catch (e) { status.textContent = 'Error: ' + e.message }
})

document.getElementById('saveDefs').addEventListener('click', async () => {
  const area = document.getElementById('defsArea')
  const status = document.getElementById('defsStatus')
  try {
    const parsed = JSON.parse(area.value)
    await putJson('/admin/data/defs', parsed)
    status.textContent = 'Saved defs.json'
  } catch (e) { status.textContent = 'Error: ' + e.message }
})

document.getElementById('loadContracts').addEventListener('click', async () => {
  const area = document.getElementById('contractsArea')
  const status = document.getElementById('contractsStatus')
  try {
    const data = await getJson('/admin/data/contracts')
    area.value = JSON.stringify(data, null, 2)
    status.textContent = 'Loaded contracts.json'
  } catch (e) { status.textContent = 'Error: ' + e.message }
})

document.getElementById('saveContracts').addEventListener('click', async () => {
  const area = document.getElementById('contractsArea')
  const status = document.getElementById('contractsStatus')
  try {
    const parsed = JSON.parse(area.value)
    await putJson('/admin/data/contracts', parsed)
    status.textContent = 'Saved contracts.json'
  } catch (e) { status.textContent = 'Error: ' + e.message }
})

// Auto-load on open
window.addEventListener('load', () => {
  document.getElementById('loadDefs').click()
  document.getElementById('loadContracts').click()
})
