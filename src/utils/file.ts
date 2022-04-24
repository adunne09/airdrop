export const fileToBase64 = async (file: any) =>
  new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onload = () => resolve(reader.result)
    reader.onerror = (error) => reject(error)
  })

export const fileToText = async (file: any) =>
  new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.readAsText(file)
    reader.onload = () => resolve(reader.result)
    reader.onerror = (error) => reject(error)
  })

export const parseStringFromFile = async (
  file: any,
  stringStartIdentifier: string,
  stringEndIdentifier: string
) => {
  try {
    const fileText = (await fileToText(file)) as string

    const stringStartIdx = fileText.indexOf(stringStartIdentifier)
    const stringEndIdx = fileText.indexOf(stringEndIdentifier)

    if (stringStartIdx === -1 || stringEndIdx === -1) {
      throw new Error('failed to parse string from file')
    }

    return fileText.slice(
      stringStartIdx,
      stringEndIdx + stringEndIdentifier.length
    )
  } catch (e) {
    return e
  }
}
