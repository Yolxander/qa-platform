"use client"

import * as React from "react"
import { IconPhoto, IconX, IconUpload, IconTrash } from "@tabler/icons-react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { supabase } from "@/lib/supabase"

interface BugImageUploadModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  bugId: number
  bugTitle: string
  onImagesUploaded?: () => void
}

interface UploadedImage {
  id: string
  url: string
  name: string
  size: number
}

export function BugImageUploadModal({
  open,
  onOpenChange,
  bugId,
  bugTitle,
  onImagesUploaded
}: BugImageUploadModalProps) {
  const [files, setFiles] = React.useState<FileList | null>(null)
  const [uploadedImages, setUploadedImages] = React.useState<UploadedImage[]>([])
  const [uploading, setUploading] = React.useState(false)
  const [dragActive, setDragActive] = React.useState(false)

  // Load existing images when modal opens
  React.useEffect(() => {
    if (open) {
      loadExistingImages()
    }
  }, [open, bugId])

  const loadExistingImages = async () => {
    try {
      if (!supabase) return

      const { data, error } = await supabase
        .from('bug_images')
        .select('*')
        .eq('bug_id', bugId)
        .order('created_at', { ascending: false })

      if (error) throw error

      const images = data?.map(img => ({
        id: img.id,
        url: img.url,
        name: img.name,
        size: img.size
      })) || []

      setUploadedImages(images)
    } catch (error) {
      console.error('Error loading existing images:', error)
    }
  }

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setFiles(e.target.files)
    }
  }

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true)
    } else if (e.type === "dragleave") {
      setDragActive(false)
    }
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    e.stopPropagation()
    setDragActive(false)
    
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      setFiles(e.dataTransfer.files)
    }
  }

  const uploadImages = async () => {
    if (!files || files.length === 0) return

    setUploading(true)
    try {
      if (!supabase) {
        console.warn('Supabase not configured')
        return
      }

      console.log('Supabase client configured:', !!supabase)
      console.log('Supabase URL:', supabase.supabaseUrl)
      
      // Check current user
      const { data: { user }, error: userError } = await supabase.auth.getUser()
      console.log('Current user:', user?.id, userError)

      // First, verify that the user has access to this bug
      const { data: bugData, error: bugError } = await supabase
        .from('bugs')
        .select(`
          id,
          projects!inner(user_id)
        `)
        .eq('id', bugId)
        .single()

      if (bugError || !bugData) {
        throw new Error('Bug not found or access denied')
      }

      const uploadPromises = Array.from(files).map(async (file) => {
        // Generate unique filename
        const fileExt = file.name.split('.').pop()
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`
        const filePath = `${bugId}/${fileName}`

        // Upload file to Supabase Storage
        console.log('Uploading file:', file.name, 'to path:', filePath)
        const { data: uploadData, error: uploadError } = await supabase.storage
          .from('bug-images')
          .upload(filePath, file)

        if (uploadError) {
          console.error('Storage upload error:', uploadError)
          throw uploadError
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
          .from('bug-images')
          .getPublicUrl(filePath)

        console.log('Generated public URL:', publicUrl)
        console.log('File path:', filePath)

        // Save image record to database
        const { data: dbData, error: dbError } = await supabase
          .from('bug_images')
          .insert({
            bug_id: bugId,
            url: publicUrl,
            name: file.name,
            size: file.size,
            path: filePath
          })
          .select()
          .single()

        if (dbError) throw dbError

        return {
          id: dbData.id,
          url: publicUrl,
          name: file.name,
          size: file.size
        }
      })

      const uploadedImages = await Promise.all(uploadPromises)
      setUploadedImages(prev => [...uploadedImages, ...prev])
      setFiles(null)
      
      // Trigger custom event to refresh images in bug details page
      window.dispatchEvent(new CustomEvent('bugImagesUpdated'))
      
      if (onImagesUploaded) {
        onImagesUploaded()
      }
    } catch (error) {
      console.error('Error uploading images:', error)
      alert('Error uploading images. Please try again.')
    } finally {
      setUploading(false)
    }
  }

  const deleteImage = async (imageId: string) => {
    try {
      if (!supabase) return

      // Get the full image record from database to get the storage path
      // This query will automatically check RLS policies to ensure user has access
      const { data: imageRecord, error: fetchError } = await supabase
        .from('bug_images')
        .select('path')
        .eq('id', imageId)
        .single()

      if (fetchError) throw fetchError

      // Delete from database
      const { error: dbError } = await supabase
        .from('bug_images')
        .delete()
        .eq('id', imageId)

      if (dbError) throw dbError

      // Delete from storage using the stored path
      if (imageRecord?.path) {
        const { error: storageError } = await supabase.storage
          .from('bug-images')
          .remove([imageRecord.path])

        if (storageError) {
          console.warn('Error deleting from storage:', storageError)
        }
      }

      // Update local state
      setUploadedImages(prev => prev.filter(img => img.id !== imageId))
      
      // Trigger custom event to refresh images in bug details page
      window.dispatchEvent(new CustomEvent('bugImagesUpdated'))
    } catch (error) {
      console.error('Error deleting image:', error)
      alert('Error deleting image. Please try again.')
    }
  }

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px] max-h-[80vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <IconPhoto className="size-5" />
            Upload Images for "{bugTitle}"
          </DialogTitle>
          <DialogDescription>
            Upload multiple images to provide visual context for this bug report.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-6">
          {/* Upload Area */}
          <div className="space-y-4">
            <Label htmlFor="image-upload">Select Images</Label>
            <div
              className={`border-2 border-dashed rounded-lg p-6 text-center transition-colors ${
                dragActive
                  ? "border-primary bg-primary/5"
                  : "border-muted-foreground/25 hover:border-primary/50"
              }`}
              onDragEnter={handleDrag}
              onDragLeave={handleDrag}
              onDragOver={handleDrag}
              onDrop={handleDrop}
            >
              <IconUpload className="mx-auto size-12 text-muted-foreground mb-4" />
              <p className="text-sm text-muted-foreground mb-2">
                Drag and drop images here, or click to select
              </p>
              <Input
                id="image-upload"
                type="file"
                multiple
                accept="image/*"
                onChange={handleFileChange}
                className="hidden"
              />
              <Button
                type="button"
                variant="outline"
                onClick={() => document.getElementById('image-upload')?.click()}
              >
                Choose Files
              </Button>
            </div>

            {files && files.length > 0 && (
              <div className="space-y-2">
                <p className="text-sm font-medium">Selected Files:</p>
                <div className="space-y-1">
                  {Array.from(files).map((file, index) => (
                    <div key={index} className="flex items-center justify-between text-sm">
                      <span className="truncate">{file.name}</span>
                      <span className="text-muted-foreground">
                        {formatFileSize(file.size)}
                      </span>
                    </div>
                  ))}
                </div>
                <Button
                  onClick={uploadImages}
                  disabled={uploading}
                  className="w-full"
                >
                  {uploading ? "Uploading..." : `Upload ${files.length} image(s)`}
                </Button>
              </div>
            )}
          </div>

          {/* Existing Images */}
          {uploadedImages.length > 0 && (
            <div className="space-y-4">
              <Label>Uploaded Images ({uploadedImages.length})</Label>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                {uploadedImages.map((image) => (
                  <div key={image.id} className="relative group">
                    <img
                      src={image.url}
                      alt={image.name}
                      className="w-full h-24 object-cover rounded-lg border"
                    />
                    <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex items-center justify-center">
                      <Button
                        size="sm"
                        variant="destructive"
                        onClick={() => deleteImage(image.id)}
                        className="h-8 w-8 p-0"
                      >
                        <IconTrash className="size-4" />
                      </Button>
                    </div>
                    <div className="mt-1 text-xs text-muted-foreground truncate">
                      {image.name}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        <div className="flex justify-end gap-2">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  )
}
