class User
  include Rails.application.routes.url_helpers
  def default_url_options
    {:host => AppConfig.pod_uri.host}
  end

  alias_method :share_with_original, :share_with

  def share_with(*args)
    fantasy_resque do
      share_with_original(*args)
    end
  end

  def post(class_name, opts = {})
    fantasy_resque do
      p = build_post(class_name, opts)
      if p.save!
        self.aspects.reload

        aspects = self.aspects_from_ids(opts[:to])
        add_to_streams(p, aspects)
        dispatch_opts = {:url => post_url(p), :to => opts[:to]}
        dispatch_opts.merge!(:additional_subscribers => p.root.author) if class_name == :reshare
        dispatch_post(p, dispatch_opts)
      end
      unless opts[:created_at]
        p.created_at = Time.now - 1
        p.save
      end
      p
    end
  end
end
