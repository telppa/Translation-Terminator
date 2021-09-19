; https://fanyi.youdao.com/

; I have tried the following methods to add text to the original text box, but all failed.
; Does anyone know the right way?

document.querySelector('#inputOriginalCopy').textContent='abc123'
document.querySelector('#inputOriginalCopy').innerText='abc123'
document.querySelector('#inputOriginalCopy').innerHTML='abc123'
document.querySelector('#inputOriginalCopy').value='abc123'

document.querySelector('#inputOriginal').textContent='abc123'
document.querySelector('#inputOriginal').innerText='abc123'
document.querySelector('#inputOriginal').innerHTML='abc123'
document.querySelector('#inputOriginal').value='abc123'