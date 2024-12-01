
import * as admin from "firebase-admin";

export const deleteUserItemFolder = async (userId: string, itemId: string) => {
  const bucket = admin.storage().bucket();
  console.log(bucket.name);

  const folderPath = `${userId}/private/${itemId}`;

  const [files] = await bucket.getFiles({
    prefix: folderPath,
  });
  console.log(`Found ${files.length} files in ${folderPath}`);
  console.log(files.map((file) => file.name));

  try {
    await bucket.deleteFiles({
      prefix: folderPath,
    });
    console.log(`Attempted to delete files from ${folderPath}`);
  } catch (error) {
    console.error(`Failed to delete files from ${folderPath}:`, error);
  }
};
