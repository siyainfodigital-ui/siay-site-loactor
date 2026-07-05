export default function SettingsPage() {
  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-primary">Settings</h2>
          <p className="text-muted-foreground">Configure application settings.</p>
        </div>
      </div>
      <div className="flex h-[400px] shrink-0 items-center justify-center rounded-md border border-dashed bg-white">
        <div className="mx-auto flex max-w-[420px] flex-col items-center justify-center text-center">
          <h3 className="mt-4 text-lg font-semibold">Coming Soon</h3>
          <p className="mb-4 mt-2 text-sm text-muted-foreground">
            The settings module is under development.
          </p>
        </div>
      </div>
    </div>
  )
}
