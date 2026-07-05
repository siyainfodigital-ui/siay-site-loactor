"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogTitle, DialogDescription } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { ChevronLeft, ChevronRight, ZoomIn, ZoomOut, Download, X, Move } from "lucide-react"

export interface ImageData {
  id: string
  url: string
  title: string
  uploadedDate: string
  uploadedTime: string
  uploadedBy: string
  lat?: string
  lng?: string
}

interface GlobalImageViewerProps {
  images: ImageData[]
  initialIndex?: number
  isOpen: boolean
  onClose: () => void
}

export function GlobalImageViewer({
  images,
  initialIndex = 0,
  isOpen,
  onClose,
}: GlobalImageViewerProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex)
  const [zoom, setZoom] = useState(1)

  if (!isOpen || images.length === 0) return null

  const currentImage = images[currentIndex]

  const nextImage = () => {
    setCurrentIndex((prev) => (prev + 1) % images.length)
    setZoom(1)
  }

  const prevImage = () => {
    setCurrentIndex((prev) => (prev - 1 + images.length) % images.length)
    setZoom(1)
  }

  const handleZoomIn = () => setZoom((prev) => Math.min(prev + 0.5, 3))
  const handleZoomOut = () => setZoom((prev) => Math.max(prev - 0.5, 1))

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-5xl w-full h-[90vh] p-0 overflow-hidden flex flex-col bg-black border-none text-white">
        
        {/* Hidden Title for Accessibility */}
        <div className="sr-only">
          <DialogTitle>Image Viewer</DialogTitle>
          <DialogDescription>Viewing image {currentImage.title}</DialogDescription>
        </div>

        {/* Toolbar */}
        <div className="flex items-center justify-between p-4 bg-black/80 z-10 absolute top-0 w-full">
          <div className="flex flex-col">
            <span className="font-semibold text-lg">{currentImage.title}</span>
            <span className="text-sm text-gray-400">
              Uploaded by {currentImage.uploadedBy} on {currentImage.uploadedDate} at {currentImage.uploadedTime}
            </span>
            {currentImage.lat && currentImage.lng && (
              <span className="text-xs text-green-400">
                GPS: {currentImage.lat}, {currentImage.lng}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="icon" onClick={handleZoomOut} className="text-white hover:bg-white/20">
              <ZoomOut className="h-5 w-5" />
            </Button>
            <Button variant="ghost" size="icon" onClick={handleZoomIn} className="text-white hover:bg-white/20">
              <ZoomIn className="h-5 w-5" />
            </Button>
            <Button variant="ghost" size="icon" className="text-white hover:bg-white/20">
              <Download className="h-5 w-5" />
            </Button>
            <Button variant="ghost" size="icon" onClick={onClose} className="text-white hover:bg-white/20">
              <X className="h-6 w-6" />
            </Button>
          </div>
        </div>

        {/* Image Area */}
        <div className="flex-1 flex items-center justify-center relative overflow-hidden bg-black/95">
          <div
            className="transition-transform duration-200 ease-in-out cursor-grab active:cursor-grabbing"
            style={{ transform: `scale(${zoom})` }}
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={currentImage.url}
              alt={currentImage.title}
              className="max-h-[80vh] object-contain pointer-events-none"
            />
          </div>

          {/* Navigation */}
          {images.length > 1 && (
            <>
              <Button
                variant="ghost"
                size="icon"
                onClick={prevImage}
                className="absolute left-4 top-1/2 -translate-y-1/2 text-white bg-black/50 hover:bg-black/80 h-12 w-12 rounded-full"
              >
                <ChevronLeft className="h-8 w-8" />
              </Button>
              <Button
                variant="ghost"
                size="icon"
                onClick={nextImage}
                className="absolute right-4 top-1/2 -translate-y-1/2 text-white bg-black/50 hover:bg-black/80 h-12 w-12 rounded-full"
              >
                <ChevronRight className="h-8 w-8" />
              </Button>
            </>
          )}
        </div>

        {/* Thumbnails */}
        {images.length > 1 && (
          <div className="h-24 bg-black/90 p-2 flex items-center justify-center gap-2 overflow-x-auto">
            {images.map((img, idx) => (
              <button
                key={img.id}
                onClick={() => {
                  setCurrentIndex(idx)
                  setZoom(1)
                }}
                className={`relative h-16 w-16 rounded-md overflow-hidden flex-shrink-0 transition-all ${
                  idx === currentIndex ? "ring-2 ring-primary scale-110" : "opacity-50 hover:opacity-100"
                }`}
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={img.url} alt={img.title} className="w-full h-full object-cover" />
              </button>
            ))}
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}
