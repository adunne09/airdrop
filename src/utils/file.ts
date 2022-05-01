export async function fileToBase64(file: Blob): Promise<MonadType<string>> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.readAsDataURL(file)

    reader.onload = () => {
      const result = reader.result as string
      resolve([result, null])
    }

    reader.onerror = (error) => {
      const message = 'failed to parse base64 from file'

      console.error(message, error)
      reject([null, message])
    }
  })
}

export async function fileToText(file: Blob): Promise<MonadType<string>> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.readAsText(file)

    reader.onload = () => {
      const result = reader.result as string
      resolve([result, null])
    }

    reader.onerror = (error) => {
      const message = 'failed to parse text from file'

      console.error(message, error)
      reject([null, message])
    }
  })
}

export async function parseStringFromFile(
  file: Blob,
  stringStartIdentifier: string,
  stringEndIdentifier: string
): Promise<MonadType<string>> {
  try {
    const [fileText, err] = await fileToText(file)
    if (err) {
      throw new Error(err.message)
    }

    const stringStartIdx = fileText.indexOf(stringStartIdentifier)
    const stringEndIdx = fileText.indexOf(stringEndIdentifier)

    if (stringStartIdx === -1 || stringEndIdx === -1) {
      throw new Error('failed to parse string from file; string not found')
    }

    return [
      fileText.slice(stringStartIdx, stringEndIdx + stringEndIdentifier.length),
      null,
    ]
  } catch (e) {
    const message = 'failed to parse string from file'

    console.error(message, e)
    return [null, { message }]
  }
}
