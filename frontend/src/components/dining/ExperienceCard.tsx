import Badge from "../ui/Badge";
import Card from "../ui/Card";
import { Experience } from "../../types";

type ExperienceCardProps = {
  experience: Experience;
};

function formatDate(value: string) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric"
  });
}

function formatCategoryLabel(value: string) {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

export default function ExperienceCard({ experience }: ExperienceCardProps) {
  return (
    <Card
      className="experience-card"
      title={experience.title || "Dining experience"}
      subtitle={`Saved ${formatDate(experience.created_at)}`}
      actions={
        experience.overall_rating !== null ? (
          <Badge tone="success">{experience.overall_rating}/5</Badge>
        ) : (
          <Badge>Unrated</Badge>
        )
      }
    >
      <div className="experience-card__meta">
        {experience.occasion ? <Badge>{experience.occasion}</Badge> : null}
        {experience.social_context ? (
          <Badge tone="accent">{experience.social_context}</Badge>
        ) : null}
      </div>

      <p className="muted experience-card__notes">
        {experience.notes || "No notes were added for this experience."}
      </p>

      {experience.ratings.length > 0 ? (
        <div className="experience-card__ratings">
          {experience.ratings.map((rating) => (
            <div key={rating.id} className="experience-rating-pill">
              <span>{formatCategoryLabel(rating.category)}</span>
              <strong>{rating.score}/5</strong>
            </div>
          ))}
        </div>
      ) : null}
    </Card>
  );
}
