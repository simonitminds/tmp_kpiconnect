defmodule Oceanconnect.Page do
  import Wallaby.Browser, only: [visit: 2, current_path: 1]

  defmacro __using__(_) do
    quote do

      def is_current_path?(session) do
        current_path(session) == @page_path
      end
      #       use Hound.Helpers
      #
      #       def has_content?(content) do
      #         String.contains?(page_source(), content)
      #       end
      #
      #       def has_css?(css) do
        #         case search_element(:css, css) do
        #           {:ok, _} -> true
      #           {:error, _} -> false
      #         end
      #       end
      #
      #       def has_no_css?(css) do
        #         case search_element(:css, css) do
        #           {:ok, _} -> false
      #           {:error, _} -> true
      #         end
      #       end
      #
      #       def has_css?(css, %{text: text}) do
      #         visible_text({:css, css}) == text
      #       end
      #
      #       def has_text?(element, %{text: text}) do
      #         String.contains?(inner_html(element), text)
      #       end
    end
  end
end
